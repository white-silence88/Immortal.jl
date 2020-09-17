module Getters
    export connection_params, channel_to_add, channel

    function connection_params(broker_config)
        adapter_field::String = "adapter"
        login_field::String = "login"
        password_field::String = "password"
        mechanism_field::String = "mechanism"
        host_field::String = "host"
        port_field::String = "port"
        vhost_field::String = "virtual_host"


        default_adapter::String = "rabbit"
        default_login::String = "guest"
        default_password::String = "guest"
        default_mechanism::String = "AMQPLAIN"
        default_host::String = "localhost"
        default_vhost::String = "/"
        default_port::Int64 = 5672

        adapter::String = get(broker_config, adapter_field, default_adapter)
        login::String = get(broker_config, login_field, default_login)
        password::String = get(broker_config, password_field, default_password)
        mechanism::String = get(broker_config, mechanism_field, default_mechanism)
        host::String = get(broker_config, host_field, default_host)
        virtual_host::String = get(broker_config, vhost_field, default_vhost)
        port::Int64 = get(broker_config, port_field, default_port)

        return adapter, mechanism, login, password, host, port, virtual_host
    end

    function channel_to_add(channel, exchangers, queues)
        result = nothing

        if channel !== nothing
            result = Dict{String, Any}(
                "CHANNEL" => channel,
                "EXCHANGERS" => exchangers,
                "QUEUES" => queues  
            )
        end

        return result
    end

    function module_name(some_module)
        return last(fullname(some_module))
    end

    function channel(connection, name, to_create, Adapter)
        return Adapter.get_channel(connection, name, to_create)
    end
end