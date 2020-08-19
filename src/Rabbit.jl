module Rabbit
    include("Chronometer.jl")
    import .Chronometer

    using AMQPClient
    export get_auth_params, get_rabbitmq_connection, get_chanel, shotdown, declare_exchange, declare_queue, delete_queue, bind_queue, unbind_queue, purge_queue, create_message

    """
        Функция создания собощения для сервера RabbitMQ
    """
    function create_message(data::Any)::AMQPClient.Message
        data_to_send = Vector{UInt8}(data)
        try
            result = AMQPClient.Message(data_to_send)
            return result
        catch error
            @error "Создание сообщения завершилось ошибкой" error
            throw(error)
        end
        return result
    end

    """
        Функция очистки очереди
    """
    function purge_queue(channel::AMQPClient.MessageChannel, queue_name::String)::Dict{String, Any}
        # Вызываем функция логирования
        @info Chronometer.message_with_time("Вызвана функция очистки очериди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        # Пробуем очистить очередь в канале по имени
        try
            # Если очередь очистится получим два значения - результат и
            # количество сообщений
            result, message_count = AMQPClient.queue_purge(channel, queue_name)
            # Дополняем логирование для режима отладки
            @debug ">> результат выполнения операции очистки очереди" result
            @debug ">> количество сообщений в очереди" message_count
            # вычисляем сообщение для логирования уровня info и выводим его
            message::String = result ? "Очередь успешно очищена" : "Не удалось совершить очистку очереди"
            @info string("=> ", message)
            # Возвращаем словарь с результатами работы функци, содержащий ключи:
            # STATUS - результат выполнения операции очистки очереди
            # QUEUE - наименование очереди
            # MSG_COUNT - количество сообщений
            return Dict{String, Any}(
                "STATUS" => result,
                "QUEUE" => queue_name,
                "MSG_COUNT" => message_count
            )
        catch error
            # Обрабатываем исключение. Выводим его в терминал и кидаем ошибку
            @error Chronometer.message_with_time("Очистка очереди завершилась с ошибкой ") error
            throw(error)
        end
    end

    """
        Функция, которая позволяет отвязать очередь от маршрута
    """
    function unbind_queue(channel::AMQPClient.MessageChannel, queue_name::String, exchanger_name::String, route_name)::Bool
        # Вызываем функця логирования
        @info Chronometer.message_with_time("Вызвана функция отвызывания от очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        @debug "> имя обменника" exchanger_name
        @debug "> имя маршрута" route_name
        # Пытаемся отвязать маршрут от череди
        try
            # Получаем результат отвязывания маршрута от очереди
            result = AMQPClient.queue_unbind(channel, queue_name, exchanger_name, route_name)
            # Дополняем логи для уровня отладки
            @debug ">> результат отвязывания очереди, обменника и маршрута" result
            # Собираем сообщение из результат
            message::String = result ? "Отвязывание от очереди и обменника прошло успешно" : "Не удалось совершить отвязывание"
            @info string("=> ", message)
            # Возвращаем результат выполнения операции отвязывания
            return result
        catch error
            # Обрабатываем ошибку: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Возникла ошибка при отвязывание")
            throw(error)
        end
    end

    """
        Функция связывание очереди и маршрута
    """
    function bind_queue(channel::AMQPClient.MessageChannel, queue_name::Any, exchanger_name::Any, route_name::String)::Dict{String, Any}
        # Выводим информационное сообщение в логер
        @info Chronometer.message_with_time("Вызвана функция связывания с очередью")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        @debug "> имя обменника" exchanger_name
        @debug "> имя маршрута" route_name
        # Пытаемся связать очередь, обменник и маршрут в канале
        try
            # Запускаем операцию связывания. Её реультат всегда типа Bool
            result::Bool = AMQPClient.queue_bind(channel, queue_name, exchanger_name, route_name)
            # Дополняем логирование для режима отладки. Выводим результат операции
            @debug ">> результат связывания очереди, обменника и маршрута" result
            # Вычисляем какое сообщение показывать в информационных логах
            message::String = result ? "Связывание очереди и обменника прошло успешно" : "Не удалось совершить связывание"
            @info string("=> ", message)
            # Возвращаем результат работы функции.
            # В качестве возвращаемого значеня используем словарь (маршрут),
            # в котором содержатся следующие ключи:
            # NAME - наименование роута
            # QUEUE - имя очереди
            # ECHANGE - имя обменника
            return Dict{String, Any}(
                "NAME" => route_name,
                "QUEUE" => queue_name,
                "EXCHANGE" => exchanger_name
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Возникла ошибка при связывании")
            throw(error)
        end
    end

    """
        Функция регистрации очереди
    """
    function declare_queue(channel::AMQPClient.MessageChannel, queue_id::String)::Dict{String, Any}
        # Выводим информационное сообщение в терминал
        @info Chronometer.message_with_time("Вызвана функция регистрации очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идетификатор очереди" queue_id
        # Пытаемся объявить очередь
        try
            # Вызываем функцию объявления очереди. В качестве результата
            # возвращаются значения
            # result - результат выполнеиня операции
            # queue_name - имя очереди
            # message_count - количество сообщений
            # consumer_count - количество потребителей
            result, queue_name, message_count, consumer_count = AMQPClient.queue_declare(channel, queue_id)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции объявления очереди" result
            @debug ">> имя очереди" queue_name
            @debug ">> количество сообщений в очереди" message_count
            @debug ">> число слушателей/потребителей" consumer_count
            # Исходя из результата вычисляем сообщение для информационного лога
            message::String = result ? "Очередь зарегистрирована удачно" : "Не удалось зарегистрировать очередь"
            @info string("=> ", message)
            # Возвращаем результат (словарь), который содержит ключи
            # STATUS - результат выполнения операции объявления
            # NAME - наименование очереди
            # MSG_COUNT - количество сообщений
            # CONS_COUNT - количество потребителей
            return Dict{String, Any}(
                "STATUS" => result,
                "NAME" => queue_name,
                "MSG_COUNT" => message_count,
                "CONS_COUNT" => consumer_count
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Регистрация очереди завершилась ошибкой ") error
            throw(error)
        end
    end


    """
        Функция удаления очереди
    """
    function delete_queue(channel::AMQPClient.MessageChannel, queue_id::Any)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функуция удаления очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идетификатор очереди" queue_id
        #
        try
            # Выполняем функцию удаления очереди, возвращается два результата
            # result - результат операции удаления
            # message_count - количество сообщений в очереди
            result, message_count = queue_delete(channel, queue_id)
            # Дополняем логирование в режиме отладки. Выводим результаты
            @debug ">> результат выполненя операции удаления очереди" result
            @debug ">> количество сообщений в очереди" message_count
            # Собираем сообщение в заивисимости от результата
            message::String = result ? "Удаление очереди прошло успешно" : "Не удалось удалить очередь"
            @info string("=> ", message)
            # Возвращаем словарь с результатами, содержащий поля:
            # STATUS - статус выполнения операции
            # MSG_COUNT - количество сообщений
            return Dict{String, Any}(
                "STATUS" => result,
                "MSG_COUNT" => message_count
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Удаление очереди завершилось ошибкой ") error
            throw(error)
        end
    end


    """
        Функция удаления обменника
    """
    function delete_exchange(channel::AMQPClient.MessageChannel, exchange_id::String)::Bool
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функция удаления обменника...")
        # Логе для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идентификатор обменника" exchange_id
        # Пытаемся удалить обменник
        try
            # Вызываем операцию удаления обменника по идентификатору
            result::Bool = AMQPClient.exchange_delete(channel, exchange_id)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции удаления обменника" result
            # В зависимости от результат присваиваем заначение сообщени
            # для информационного уровня логирования и выводим его
            message::String = result ? "Обменник успешно удалён" : "Не удалось удалить обменник"
            @info string("=>", message)
            # Возвращаем результат выполения операции
            return result
        catch error
            #
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой ") error
            throw(error)
        end
    end


    """
        Функция регистрации обменника
    """
    function declare_exchange(channel::AMQPClient.MessageChannel, exc_id::String, exc_type::String)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функция регистрации обменника...")
        # Логерд для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с сервером RabbitMQ" channel
        @debug "> идентификатор обменника" exc_id
        @debug "> тип обменника" exc_type
        # Инициализируем переменную типа обменника с пустым значением
        exchange_type = nothing
        # Задаём тип обменника в зависимости от переданного наименования типа
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
        # Дополняем логирвание для режима отладки
        @debug ">> вычисленный тип обменника" exchange_type
        # Пытаемся объявить обменник
        try
            # Вызываем операцию объявления (регистрации) обменника на сервер RabbitMQ
            result::Bool = AMQPClient.exchange_declare(channel, exc_id, exchange_type)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции регистрации обменника" result
            # В зависимости от результата операции задаём значение сообщения для
            # информационног уровня логирования и выводим его
            message::String = result ? "Регистрация обменника прошла успешно" : "Не удалось ззарегистрировать обменник"
            @info string("=> ", message)
            # В качестве результата возвращаем словарь, содержащий ключи:
            # NAME - наименование обменника
            # TYPE - тип обменника
            return Dict{String, Any}(
                "NAME" => exc_id,
                "TYPE" => exchange_type
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой") error
            throw(error)
        end
    end


    """
        Функция закрывает соединение
    """
    function shotdown(conection::AMQPClient.MessageChannel)
        # Выводим информационное сообщение
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
        #
        @info Chronometer.message_with_time("Вызвана функция создания канала для соединения в очереди на сервисе очередей...")
        # Логерд для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> соединение с сервисом очередей" connection
        @debug "> идентификатор канала" chanid
        @debug "> необходимость создания канала (если его нет)" create
        # Инициализируем идентификатор канала.
        # Если он передан в параметрах функции - то присваиваем его
        # Если он не передан в параметрах функции - то генерим начение
        channel_id = chanid == nothing ? AMQPClient.UNUSED_CHANNEL : chanid
        # Создаем новый канал для соединения
        try
            # Выполняем операцию создания/поиска канала
            result::AMQPClient.MessageChannel = AMQPClient.channel(connection, channel_id, create)
            # Выводим информационное сообщение
            @info "=> Канал успешно создан!"
            # Возвращаем результат
            return result
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Ошибка при создании канала") error
            throw(error)
        end
    end

    """
        Функция для получения параметров авторизации на RabbitMQ
    """
    function get_auth_params(login::String, password::String)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Вызвана функция сборки параметров соединеня с сервисом очередей...")
        # Логирование для режима отладки
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
        #
        @info Chronometer.message_with_time("Вызвана функция соединения с сервером очередей RabbitMQ...")
        # Логе для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> виртуальный хост" vhost
        @debug "> хост сервера RabbitMQ" host
        @debug "> порт сервера RabbitMQ" port
        @debug "> параметры авторизации на сервере RabbitMQ" auth_params
        # Получаем соединение с сервером очередей RabbitMQ
        try
            # Выполняем операцию соединения
            result::AMQPClient.MessageChannel = AMQPClient.connection(
                ;virtualhost=vhost,
                host=host,
                port=port,
                auth_params=auth_params
            )
            # Выводим информационное сообщение
            @info "=> Соединене успешно установлено!"
            # Возвращаем результат
            return result
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Не удалось установить соединене с RabbitMQ. Ошибка") error
            throw(error)
        end
    end
end
