module Immortal
    include("Rabbit.jl")
    import .Rabbit


    """
        Функция для запуска сервера для работы с Rabbit
    """
    function run(login::String, password::String, vhost::String, port::Int64)
        @info "Вызвана функция запуска сервера..."
        # Задаём значение хоста по умолчанию
        host::String = "api.seon.cloud"
        # Логер вызова функции для режима отладки
        @debug "Параметры вызова функции:"
        @debug "- логин пользователя для подключения к серверу RabbitMQ" login
        @debug "- пароль пользователя для подключения к серверу RabbitMQ" password
        @debug "- virtialhost для подключения к серверу RabbitMQ" vhost
        @debug "- порт для подключения к серверу RabbitMQ" port
        @debug "- хост для подключения к серверу RabbitMQ" host
        # Задаем значение статуса соединеня с сервером RabbitMQ
        is_connected::Bool = false
        # Инициализируем переменную соединения с пустым значеним
        connection = nothing

        # Подключаемся к серверу RabbitMQ
        try
            # Получаем параметры автризации на сервисе очередей
            auth_params::Dict{String, Any} = Rabbit.get_auth_params(login, password)
            # Получаем соединени с сервером очередей
            connection = Rabbit.get_rabbitmq_connection(vhost, host, port, auth_params)
            # Создаём канал для работы с сервисом очередей
            chanel = Rabbit.get_chanel(connection, nothing, true)
            # Меняем значение статуса соединеня
            is_connected = true
        catch error
            @error "Завершение работы сервера. Ошибка" error
            exit()
        end

        Rabbit.shotdown(connection)
    end
end
