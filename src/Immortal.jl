module Immortal
    # Подключаем библиотеку, связанную с временем
    include("Chronometer.jl")
    import .Chronometer

    # Подключаем библиотеку, связанную с сервисом работы очередей RabbitMQ
    include("Rabbit.jl")
    import .Rabbit


    """
        Функция для запуска сервера для работы с Rabbit
    """
    function run(login::String, password::String, vhost::String, port::Int64)
        @info Chronometer.message_with_time("Вызвана функция запуска сервера...")
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
            # Создаём обменник
            exchanger::Dict{String, Any} = Rabbit.declare_exchange(chanel, "test", "direct")
            # Регистрируем очередь внутри виртуалхоста
            queue_1::Dict{String, Any} = Rabbit.declare_queue(chanel, "MyFirstQueue")
            queue_2::Dict{String, Any} = Rabbit.declare_queue(chanel, "MySecondQueue")
            q1_name::Any = get(queue_1, "NAME", nothing)
            q2_name::Any = get(queue_2, "NAME", nothing)
            queue_1_deleted::Dict{String, Any} = Rabbit.delete_queue(chanel, q1_name)

            exchanger_name::Any = get(exchanger, "NAME", nothing)
            route::Dict{String, Any} = Rabbit.bind_queue(chanel, q2_name, exchanger_name, "MyTestRoute")
            route_name::Any = get(route, "NAME", nothing)

            example_data = "Hello, world"
            msg = Rabbit.create_message(example_data)

            purge_messages = Rabbit.purge_queue(chanel, q2_name)
            reoute_deleted::Bool = Rabbit.unbind_queue(chanel, q2_name, exchanger_name, route_name)
            # Удаление обменника
            exchange_deleted::Bool = Rabbit.delete_exchange(chanel, exchanger_name)

            # Меняем значение статуса соединеня
            is_connected = true
        catch error
            @error Chronometer.message_with_time("Завершение работы сервера. Ошибка") error
            exit()
        end

        Rabbit.shotdown(connection)
    end
end
