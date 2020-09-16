module Immortal
    # Подключаем библиотеку, связанную с временем
    include("./utils/Utils.jl")
    import .Utils

    # Подключаем библиотеку для работы с RabbitMQ и каналами
    include("./rabbitmq/Rabbit.jl")
    import .Rabbit

    export init, declares, get_adapter

    function get_adapter(value)
        adapter = nothing
        adapter_name = nothing
        value_type = typeof(value)

        if value_type === String
            adapter_name = value
        elseif value_type == Dict{String, Any}
            adapter_name = get(value, "adapter", "rabbit")
        else 
            adapter_name = nothing
        end

        if adapter_name === "rabbit"
            adapter = Rabbit
        else
            adapter = nothing
        end

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
                # exchangers, queues = Utils.Declares.in_channel(channel, channel_config, Adapter)
                # channel_to_add = Utils.Getters.channel_to_add(channel, exchangers, queues)

                # if channel_to_add !== nothing 
                #     if results === nothing
                #         results = Dict{String, Dict{String, Any}}(name => channel_to_add)
                #     else
                #         push!(resultsg, name => channel_to_add)
                #     end
                # end
            end

            return results
        catch error
            @error error
            throw(error)
        end
    end
end
