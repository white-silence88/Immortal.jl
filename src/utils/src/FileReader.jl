module FileReader
    using YAML
    include("./Chronometer.jl")
    import .Chronometer
    
    """Функция импорта настроек из YAML файла

    file_path: путь до файла.
    """
    function from_yaml(file_path::String)::Union{Dict{String, Any}, Nothing}
        @info Chronometer.message_with_time("Выполняется функция чтения данных из YAML файла...")
        @debug "Параметры вызова функции:"
        @debug "- путь до файла в файловой системе (полный путь)" file_path
        result::Union{Dict{String, Any}, Nothing} = nothing
        @debug "Инициализируем результат с пустым значенем" result
        if file_path !== nothing
            try
                @debug "Пытаемся прочитать содержимое файла"
                result = YAML.load_file(file_path)
                @debug "Результат чтения содержимого файла" result
            catch error
                @error Chronometer.message_with_time("Произошла ошибка при чтении файла $file_path") error
            end
        end
        return result
    end
end