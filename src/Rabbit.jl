module Rabbit
    include("Chronometer.jl")
    import .Chronometer

    using AMQPClient
    export get_auth_params, get_rabbitmq_connection, get_chanel, shotdown, declare_exchange, declare_queue, delete_queue, bind_queue, unbind_queue, purge_queue

    """
        Функция очистки очереди
    """
    function purge_queue(channel::AMQPClient.MessageChannel, queue_name::String)::Dict{String, Any}
        @info Chronometer.message_with_time("Вызвана функция очистки очериди...")
        
        try
            result, message_count = AMQPClient.queue_purge(channel, queue_name)
            message::String = result ? "Очередь успешно очищена" : "Не удалось совершить очистку очереди"
            @info string("=> ", message)
            return Dict{String, Any}(
                "STATUS" => result,
                "QUEUE" => queue_name,
                "MSG_COUNT" => message_count
            )
        catch error
            @error Chronometer.message_with_time("Очистка очереди завершилась с ошибкой ") error
            throw(error)
        end
    end

    """
        Функция, которая позволяет отвязать очередь от маршрута
    """
    function unbind_queue(channel::AMQPClient.MessageChannel, queue_name::String, exchanger_name::String, route_name)::Bool
        @info Chronometer.message_with_time("Вызвана функция отвызывания от очереди...")
        try
            result = AMQPClient.queue_unbind(channel, queue_name, exchanger_name, route_name)

            message::String = result ? "Отвязывание от очереди и обменника прошло успешно" : "Не удалось совершить отвязывание"
            @info string("=> ", message)

            return result
        catch error
            @error Chronometer.message_with_time("Возникла ошибка при отвязывание")
            throw(error)
        end
    end

    """
        Функция связывание очереди и маршрута
    """
    function bind_queue(channel::AMQPClient.MessageChannel, queue_name::Any, exchanger_name::Any, route_name::String)::Dict{String, Any}
        @info Chronometer.message_with_time("Вызвана функция связывания с очередью")
        try
            result = AMQPClient.queue_bind(channel, queue_name, exchanger_name, route_name)

            message::String = result ? "Связывание очереди и обменника прошло успешно" : "Не удалось совершить связывание"
            @info string("=> ", message)

            return Dict{String, Any}(
                "NAME" => route_name,
                "QUEUE" => queue_name,
                "EXCHANGE" => exchanger_name
            )
        catch error
            @error Chronometer.message_with_time("Возникла ошибка при связывании")
            throw(error)
        end
    end

    """
        Функция регистрации очереди
    """
    function declare_queue(channel::AMQPClient.MessageChannel, queue_id::String)::Dict{String, Any}
        @info Chronometer.message_with_time("Вызвана функция регистрации очереди...")
        try
            success, queue_name, message_count, consumer_count = AMQPClient.queue_declare(channel, queue_id)
            message::String = success ? "Очередь зарегистрирована удачно" : "Не удалось зарегистрировать очередь"
            @info string("=> ", message)
            return Dict{String, Any}(
                "STATUS" => success,
                "NAME" => queue_name,
                "MSG_COUNT" => message_count,
                "CONS_COUNT" => consumer_count
            )
        catch error
            @error Chronometer.message_with_time("Регистрация очереди завершилась ошибкой ") error
        end
    end


    """
        Функция удаления очереди
    """
    function delete_queue(channel::AMQPClient.MessageChannel, queue_id::Any)::Dict{String, Any}
        @info Chronometer.message_with_time("Запущена функуция удаления очереди...")
        try
            success, message_count = queue_delete(channel, queue_id)
            message::String = success ? "Удаление очереди прошло успешно" : "Не удалось удалить очередь"
            @info string("=> ", message)
            return Dict{String, Any}(
                "STATUS" => success,
                "MSG_COUNT" => message_count
            )
        catch error
            @error Chronometer.message_with_time("Удаление очереди завершилось ошибкой ") error
        end
    end


    """
        Функция удаления обменника
    """
    function delete_exchange(channel::AMQPClient.MessageChannel, exchange_id::String)::Bool
        @info Chronometer.message_with_time("Запущена функция удаления обменника...")
        try
            result::Bool = AMQPClient.exchange_delete(channel, exchange_id)
            message::String = result ? "Обменник успешно удалён" : "Не удалось удалить обменник"
            @info string("=>", message)
            return result
        catch error
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой ") error
            throw(error)
        end
    end


    """
        Функция регистрации обменника
    """
    function declare_exchange(channel::AMQPClient.MessageChannel, exc_id::String, exc_type::String)::Dict{String, Any}
        @info Chronometer.message_with_time("Запущена функция регистрации обменника...")

        exchange_type = nothing

        if exc_type == "direct"
            exchange_type = AMQPClient.EXCHANGE_TYPE_DIRECT
        elseif exc_type == "fanout"
            exchange_type = AMQPClient.EXCHANGE_TYPE_FANOUT
        elseif exc_type == "topic"
            exchange_type = AMQPClient.EXCHANGE_TYPE_TOPIC
        elseif exc_type == "headers"
            exchange_type = AMQPClient.EXCHANGE_TYPE_HEADERS
        else
            exchange_type = AMQPClient.EXCHANGE_TYPE_DIRECT
        end

        try
            result::Bool = AMQPClient.exchange_declare(channel, exc_id, exchange_type)
            message::String = result ? "Регистрация обменника прошла успешно" : "Не удалось ззарегистрировать обменник"
            @info string("=> ", message)
            return Dict{String, Any}(
                "NAME" => exc_id,
                "TYPE" => exchange_type
            )
        catch error
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой") error
            throw(error)
        end
    end


    """
        Функция закрывает соединение
    """
    function shotdown(conection::AMQPClient.MessageChannel)
        @info Chronometer.message_with_time("Вызывана функция остановки сервера...")
        # Логер для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> соединение с сервером очередей RabbitMQ" conection
        # Проверяем открыто ли соединение на данный момент
        if AMQPClient.isopen(conection)
            # Закрываем соединение
            AMQPClient.close(conection)
            # Закрытие соединеня асинхронная операция. Ждём завершения для всех каналов
            AMQPClient.wait_for_state(conection, AMQPClient.CONN_STATE_CLOSED)
        end
    end


    """
        Функция создания канала для соединения RabbitMQ
    """
    function get_chanel(connection::AMQPClient.MessageChannel, chanid::Union{String, Nothing}, create::Bool)::AMQPClient.MessageChannel
        @info Chronometer.message_with_time("Вызвана функция создания канала для соединения в очереди на сервисе очередей...")
        # Логерд для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> соединение с сервисом очередей" connection
        @debug "> идентификатор канала" chanid
        @debug "> необходимость создания канала (если его нет)" create
        # Инициализируем идентификатор канала.
        # Если он передан в параметрах функции - то присваиваем его
        # Если он не передан в параметрах функции - то генерим начение
        chanell_id = chanid == nothing ? AMQPClient.UNUSED_CHANNEL : chanid
        # Создаем новый канал для соединения
        try
            result::AMQPClient.MessageChannel = AMQPClient.channel(connection, chanell_id, create)
            @info "=> Канал успешно создан!"
            return result
        catch error
            @debug Chronometer.message_with_time("Ошибка при создании канала") error
            throw(error)
        end
        return result
    end

    """
        Функция для получения параметров авторизации на RabbitMQ
    """
    function get_auth_params(login::String, password::String)::Dict{String, Any}
        @info Chronometer.message_with_time("Вызвана функция сборки параметров соединеня с сервисом очередей...")
        @debug "Параметры вызова функции:"
        @debug "> имя пользователя на сервисе очередей" login
        @debug "> пароль пользователя на сервисе очередей" password
        # Задаём механиз соединения по умолчанию
        mechanism::String = "AMQPLAIN"
        @debug "> механизм соединеня на сервисе очередей" mechanism
        # Создаём словарь с параметрами авторизации на сервисе очередей
        # Важно! Тип данного словаря должен быть именно {String, Any}!
        # При смене типа словаря параметров соединене с сервером отказывается
        # устаналиваться.
        #Такой тип задан в файле:
        # * https://github.com/JuliaComputing/AMQPClient.jl/blob/master/src/auth.jl
        result::Dict{String,Any} = Dict{String, Any}(
            "MECHANISM" => mechanism,
            "LOGIN" => login,
            "PASSWORD" => password
        )
        @debug "=> Результат сборки параметров авторизации" result
        # Возвращаем результат (словарь настроек)
        return result
    end

    """
        Функция для получения установки соединения с сервером RabbitMQ
    """
    function get_rabbitmq_connection(vhost::String, host::String, port::Int64, auth_params::Dict{String, Any})::AMQPClient.MessageChannel
        @info Chronometer.message_with_time("Вызвана функция соединения с сервером очередей RabbitMQ...")
        # Логе для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> виртуальный хост" vhost
        @debug "> хост сервера RabbitMQ" host
        @debug "> порт сервера RabbitMQ" port
        @debug "> параметры авторизации на сервере RabbitMQ" auth_params
        # Получаем соединение с сервером очередей RabbitMQ
        try
            result::AMQPClient.MessageChannel = AMQPClient.connection(
                ;virtualhost=vhost,
                host=host,
                port=port,
                auth_params=auth_params
            )
            @info "=> Соединене успешно установлено!"
            return result
        catch error
            @error Chronometer.message_with_time("Не удалось установить соединене с RabbitMQ. Ошибка") error
            throw(error)
        end
    end
end
