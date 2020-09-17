module FileReader

    # Подключааем библиотеку для работы с YAML 
    using YAML
    # Подключаем библиотеку для работы с JSON
    using JSON

    # Подключаем библиотеку для работы со временем
    include("./Chronometer.jl")
    import .Chronometer

    """Функция импорта настроек из JSON файла

    file_path: путь до файла.
    """
    function from_json(file_path::String)
        @info Chronometer.message_with_time("Выполняется функция чтения данных из JSON файла...")

        @debug "Параметры вызова функции:"
        @debug "- путь до файла в файловой системе (полный путь)" file_path
        
        result = nothing
        
        @debug "Инициализируем результат с пустым значенем" result
        
        try
            @debug "Пытаемся открыть файл в файловой системе"
            file = open(file_path)

            @debug "Результат открытия файла" file
            @debug "Пытаемся прочитать данные из файла"
            data = read(file, String)    
            
            @debug "Результат чтения данных из файла" data
            @debug "Пытаемся распарсить строку JSON в словарь"
            result = JSON.parse(data)
            
            @debug "Результат парсинга JSON строки" result
        catch error
            @error Chronometer.message_with_time("Не удалось прочитать JSON файл. Ошибка: ") error
        end

        return result
    end

    """Функция импорта настроек из YAML файла

    file_path: путь до файла.
    """
    function from_yaml(file_path::String)::Union{Dict{String, Any}, Nothing}
        @info Chronometer.message_with_time("Выполняется функция чтения данных из YAML файла...")
   
        @debug "Параметры вызова функции:"
        @debug "> путь до файла в файловой системе (полный путь)" file_path
   
        result::Union{Dict{String, Any}, Nothing} = nothing
        @debug "Инициализируем результат с пустым значенем" result

        # Читаем файл если путь существует
        if file_path !== nothing
            try
                @debug "Пытаемся прочитать содержимое файла по пути" file_path
                result = YAML.load_file(file_path; dicttype=Dict{String,Any})
                @debug "Результат чтения содержимого файла" result
            catch error
                @error Chronometer.message_with_time("Произошла ошибка при чтении файла $file_path") error
            end
        end

        return result
    end
end