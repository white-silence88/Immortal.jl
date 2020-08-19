module Rabbit
    include("Chronometer.jl")
    import .Chronometer

    using AMQPClient
    export get_auth_params, get_rabbitmq_connection, get_chanel, shotdown


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
            @info Chronometer.message_with_time("Канал успешно создан!")
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
        @debug Chronometer.message_with_time("% Результат сборки параметров авторизации") result
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
            @info Chronometer.message_with_time("Соединене успешно установлено!")
            return result
        catch error
            @error Chronometer.message_with_time("Не удалось установить соединене с RabbitMQ. Ошибка") error
            throw(error)
        end
    end
end
