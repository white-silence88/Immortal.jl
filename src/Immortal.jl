module Immortal
    # Подключаем библиотеку, связанную с временем
    include("./utils/Utils.jl")
    import .Utils

    # Подключаем библиотеку для работы с RabbitMQ и каналами
    include("./rabbitmq/Rabbit.jl")
    import .Rabbit

    export init, declares, get_adapter

    """ Функция получения адаптера для сервера очередей

    value: словарь настроек брокера или имя адаптера сервера очередей
    """
    function get_adapter(value)
        @info Utils.Chronometer.message_with_time("Вызвана функция получения адаптера брокера сообщений/очередей...")
        @debug "Параметры вызова функции:"
        @debug "> параметр для получения адаптера брокера" value
        adapter = nothing
        @debug "Инициализирован параметр adapter с пустым значением"
        adapter_name = nothing
        @debug "Инициализирован параметр adapter_name с пустым значением"
        value_type = typeof(value)
        @debug "Получили тип переданного в функцию параметра" value_type
        @debug "Сопоставляем тип переданного параметра. В зависимости от него продоим вычисление параматра adapter_name"
        if value_type === String
            @debug "Тип переданного значения определился как строка. Считаем переданное значение именем адаптера" value
            adapter_name = value
        elseif value_type == Dict{String, Any}
            @debug "Тип переданного значения опредилился как словарь (String, Any). Получаем имя адаптера из словаря"
            adapter_name = get(value, "adapter", "rabbit")
        else 
            @debug "Нет корретного значеня типа. Считаем имя адаптера - пустым"
            adapter_name = nothing
        end

        @debug "По имени адаптера присваиваем модуль"
        if adapter_name === "rabbit"
            @debug "Адаптеру соответствует модуль для работы с RabbitMQ"
            adapter = Rabbit
        else
            @debug "Нет совпадений модулей адаптеров"
            adapter = nothing
        end

        @debug "Возвразаем адаптер" adapter
        return adapter
    end

    function init(config_path::String)
        try
            connection = nothing
            broker_config, channels_config = Utils.ConfigReader.get_configs(config_path)
            adapter, mechanism, login, password, host, port, virtual_host = Utils.Getters.connection_params(broker_config)

            Adapter = get_adapter(adapter)

            if Adapter !== nothing
                auth_params = Adapter.get_auth_params(login, password, mechanism)
                connection = Adapter.get_connection(virtual_host, host, port, auth_params)
            end

            return connection, broker_config, channels_config    
        catch error
            @error error
            throw(error)  
        end
    end

    function declares(connection, broker_config, channels_config)
        try
            Adapter = get_adapter(broker_config)

            results = nothing

            names = keys(channels_config)
            for name in names
                channel_config = get(channels_config, name, nothing)

                channel = Utils.Getters.channel(connection, name, true, Adapter)
                exchangers, queues = Utils.Declares.in_channel(channel, channel_config, Adapter)
                channel_to_add = Utils.Getters.channel_to_add(channel, exchangers, queues)
                if channel_to_add !== nothing 
                    if results === nothing
                       results = Dict{String, Dict{String, Any}}(name => channel_to_add)
                    else
                        push!(resultsg, name => channel_to_add)
                    end
                end
            end

            return results
        catch error
            @error error
            throw(error)
        end
    end
end
