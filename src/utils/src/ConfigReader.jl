module ConfigReader
    include("./FileReader.jl")
    import .FileReader

    include("./Chronometer.jl")
    import .Chronometer

    export read, get_configs

    """Функция получения конфигурации сервера из YAML или JSON файла.

    config_path: строка с полным путём до файла конфигурации
    """
    function read(config_path::String)::Union{Dict{String, Any}, Nothing}
        is_yaml::Bool = findfirst(".yml", config_path) === nothing ? false : true
        is_json::Bool = findfirst(".json", config_path) === nothing ? false : true 
        config::Union{Dict{String, Any}, Nothing} = nothing 
        try
            if is_yaml === true
                config = FileReader.from_yaml(config_path)
            elseif  is_json === true
                config = FileReader.from_json(config_path)
            else
                config = nothing
            end
        catch error
            @error Chronometer.message_with_time("Произошла ошибка при запуске сервера") error
            throw(error)
        end
    end
    
    function get_configs(path::String)
        common_config::Union{Dict{String, Any}, Nothing} = read(path)

        rabbit_config::Union{Dict{String, Any}, Nothing} = nothing
        channels_config::Union{Dict{String, Any}, Nothing} = nothing
        broker_config::Union{Dict{String, Any}, Nothing} = nothing

        broker_field::String = "broker"
        channels_field::String = "channels"

        default_value::Nothing = nothing
        

        if common_config !== nothing
            broker_config = get(common_config, broker_field, default_value)
            channels_config = get(common_config, channels_field, default_value)
        end

        return broker_config, channels_config
    end
end