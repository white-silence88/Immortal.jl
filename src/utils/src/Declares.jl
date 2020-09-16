module Declares

    export queues, exchangers, in_channel

    """
    """
    function queues(channel, queues_names, Adapter)
        queues = nothing 

        for name in queues_names
            queue = Adapter.Queues.declare(channel, name)
            if queue !== nothing
                if queues === nothing
                    queues = Dict{String, Any}(name => queue)
                else
                    push!(queues, name => queue)
                end
            end
        end
        
        return queues
    end

    """
    """
    function exchangers(channel, exchangers_configs, Adapter)
        exchangers = nothing
        
        name_field::String = "name"
        type_field::String = "type"

        for exchanger_config in exchangers_configs
            name = get(exchanger_config, name_field, nothing)
            type = get(exchanger_config, type_field, "direct")

            if name !== nothing
                exchanger::Dict{String, Any} = Adapter.Exchanges.declare(channel, name, type)
                if exchangers === nothing
                    exchangers = Dict{String, Any}(name => exchanger)
                else
                    push!(exchangers, name => exchanger)
                end
            end
        end

        return exchangers
    end

    function in_channel(channel, channel_config, Adapter)
        exchangers_dict = nothing
        queues_dict = nothing

        queues_field::String = "queues"
        exchangers_field::String = "exchangers"

        if channel_config !== nothing && channel !== nothing
            exchangers_list = get(channel_config, exchangers_field, nothing)
            queues_list = get(channel_config, queues_field, nothing)

            exchangers_dict = exchangers(channel, exchangers_list, Adapter)
            queues_dict = queues(channel, queues_list, Adapter)
        end

        return exchangers_dict, queues_dict
    end
end