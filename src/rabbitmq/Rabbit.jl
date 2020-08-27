module Rabbit
    # Подключаем библиотеку, связанную с временем
    include("../utils/Utils.jl")
    import .Utils

    # Подключаем библиотеку для работы с обменником
    include("./src/Exchanges.jl")
    import .Exchanges
    # Подключаем библиотеку для работы с очередью
    include("./src/Queues.jl")
    import .Queues
    # Подключаем библиотеку для работы с сообщениями
    include("./src/Messages.jl")
    import .Messages

    using AMQPClient

    export shotdown, get_channel, get_auth_params, get_connection

    """Функция закрывает соединение.


    connection: активное соединение с сервисом очередей
    """
    function shotdown(conection::AMQPClient.MessageChannel)
        # Выводим информационное сообщение
        @info Utils.Chronometer.message_with_time("Вызывана функция остановки сервера...")
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


    """Функция создания канала для соединения RabbitMQ.


    connection: активное соединение с сервисом очередей, 
    chanid: идентификатор канала, 
    create: опция, которая показывает требуется ли создать канал, если его не существует
    """
    function get_channel(connection::AMQPClient.MessageChannel, chanid::Union{String, Nothing}, create::Bool)::AMQPClient.MessageChannel
        #
        @info Utils.Chronometer.message_with_time("Вызвана функция создания канала для соединения в очереди на сервисе очередей...")
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
            @error Utils.Chronometer.message_with_time("Ошибка при создании канала") error
            throw(error)
        end
    end

    """Функция для получения параметров авторизации на RabbitMQ.


    login: логин пользователя на сервисе очередей, 
    password: пароль от пользователя на сервисе очередей
    """
    function get_auth_params(login::String, password::String)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Utils.Chronometer.message_with_time("Вызвана функция сборки параметров соединеня с сервисом очередей...")
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

    """Функция для получения установки соединения с сервером RabbitMQ.

    vhost: виртуальный хост на сервисе очередей,  
    host: хост для подключенияя к сервису очередей, 
    port: порт для подключения к сервису очередей,
    auth_params: параметры авторизации на сервисе очередей
    """
    function get_connection(vhost::String, host::String, port::Int64, auth_params::Dict{String, Any})::AMQPClient.MessageChannel
        #
        @info Utils.Chronometer.message_with_time("Вызвана функция соединения с сервером очередей RabbitMQ...")
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
            @error Utils.Chronometer.message_with_time("Не удалось установить соединене с RabbitMQ. Ошибка") error
            throw(error)
        end
    end
end
