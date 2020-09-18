module Immortal
    # Подключаем библиотеку, связанную с временем
    include("./utils/Utils.jl")
    import .Utils

    # Подключаем библиотеку для работы с RabbitMQ и каналами
    include("./rabbitmq/Rabbit.jl")
    import .Rabbit

    export init, declares, get_adapter, ImmortalApplication

    """
    """
    mutable struct ImmortalApplication
        connection
        adapter
        broker_config::Dict{String, Any}
        channels_config::Dict{String, Any}
        channels: Array{ImmortalChannel}
    end

    """Канал брокера очередей фреймворка Immortal. Включает в себя много параметров, в т.ч. индефикатор и коннект

    id: индефикатор канала
    channel: соединение канала
    exchangers: словарь с обменниками
    queues: словарь с очередями
    """
    mutable struct ImmortalChannel
        id::Union{String, Int64}
        channel
        exchangers::Dict{String, Any}
        queues::Dict{String, Any}
    end

    """ Функция получения адаптера для сервера очередей

    value: словарь настроек брокера или имя адаптера сервера очередей
    """
    function get_adapter(value)
        @info Utils.Chronometer.message_with_time("Вызвана функция получения адаптера брокера сообщений/очередей...")
        
        @debug "Параметры вызова функции:"
        @debug "- параметр для получения адаптера брокера" value
        
        adapter = nothing
        @debug "Инициализирован параметр adapter с пустым значением" adapter
        
        adapter_name = nothing
        @debug "Инициализирован параметр adapter_name с пустым значением" adapter_name

        value_type = typeof(value)
        @debug "Получили тип переданного в функцию параметра" value_type
        
        @debug "Сопоставляем тип переданного параметра. В зависимости от него продоим вычисление параматра adapter_name"
        if value_type === String
            adapter_name = value
            @debug "> Тип переданного значения определился как строка. Считаем переданное значение именем адаптера" adapter_name
        elseif value_type == Dict{String, Any}
            adapter_name = get(value, "adapter", "rabbit")
            @debug "> Тип переданного значения опредилился как словарь (String, Any). Получаем имя адаптера из словаря" adapter_name
        else 
            adapter_name = nothing
            @debug "> Нет корретного значеня типа. Считаем имя адаптера - пустым" adapter_name
        end

        @debug "По имени адаптера присваиваем модуль"
        if adapter_name === "rabbit"
            adapter = Rabbit
            @debug "> Адаптеру соответствует модуль для работы с RabbitMQ" adapter
        else
            adapter = nothing
            @debug "> Нет совпадений модулей адаптеров" adapter
        end

        @debug "Возвразаем адаптер" adapter
        return adapter
    end

    """Функция инициализации фреймворка

    config_path: путь до файла конфигурации
    """
    function init(config_path::String)::Union{ImmortalApplication, Nothing}
        @info Utils.Chronometer.message_with_time("Вызвана функция инициализации приложения...")
        @debug "Инициализируем пустое приложение"
        application::Union{ImmortalApplication, Nothing} = nothing

        @debug "Параметры вызова функции:"
        @debug "- полный путь до файла" config_path

        @debug "Получаем настроки брокера и коннект"
        try
            @debug "> Соединение с сервером очередей"
            connection = nothing

            broker_config, channels_config = Utils.ConfigReader.get_configs(config_path)
            @debug "> Конфигурация брокера" broker_config
            @debug "> Конфигурация каналов" channels_config

            adapter, mechanism, login, password, host, port, virtual_host = Utils.Getters.connection_params(broker_config)
            @debug "> Наименование адаптера" adapter
            @debug "> Механизм соединения/авторизации" mechanism
            @debug "> Логин пользователя на сервере очередей" login
            @debug "> Пароль пользователя на сервере очередей" password
            @debug "> Хост сервере очередей" host
            @debug "> Порт сервера очередей" port
            @debug "> Виратульный хост сервера очередей" virtual_host

            Adapter = get_adapter(adapter)
            @debug "> Адаптер брокера очередей" Adapter

            @debug "> Устаналиваем соединение с брокером..."
            if Adapter !== nothing
                auth_params = Adapter.get_auth_params(login, password, mechanism)
                @debug ">> Параметры авторизации на брокере очередей" auth_params

                connection = Adapter.get_connection(virtual_host, host, port, auth_params)
                @debug ">> Соединение с брокером очередей" connection
            end

            @debug "> Соединение с брокером очередей" connection
            @debug "> Конфигурация для брокера очередей" broker_config
            @debug "> Конфигурация для каналов на брокере очередей" channels_config

            application = ImmortalApplication(connection, Adapter, broker_config, channels_config, [])
            @debug "> Новое значение для приложения" application
            
        catch error
            @error Utils.Chronometer.message_with_time("Не удалос инициализировать Immortal") error
            throw(error)  
        end

        @debug "Результат инициализации" application
        return application
    end

    """Функция объявления очередей, обменников и т.п. 

    application: приложение Immortal
    - connection: свойство, содержащее соединение
    - adapter: свойство, содержащее адаптер
    - broker_config: свойство, содержащее конфигурацию брокера
    - channel_config: свойство, содержащее конфигурацию каналов
    """
    function declares(application::ImmortalApplication)::ImmortalApplication
        try
            results::Array{ImmortalChannel} = []

            connection = application.connection
            adapter = application.adapter
            broker_config::Dict{String, Any} = application.broker_config
            channels_config::Dict{String, Any} = application.channels_config

            names = keys(channels_config)
            for name in names
                channel_id::Int64 = adapter.get_channel_id(name)
                channel_config = get(channels_config, name, nothing)

                channel = Utils.Getters.channel(connection, channel_id, true, Adapter)
                exchangers, queues = Utils.Declares.in_channel(channel, channel_config, Adapter)

                if channel !== nothing
                    channel_to_add = ImmortalChannel(channel_id, channel, exchangers, queues)
                    append!(results, channel_to_add)
                end
            end

            application.channels = results

            return application
        catch error
            @error error
            throw(error)
        end
    end
end
