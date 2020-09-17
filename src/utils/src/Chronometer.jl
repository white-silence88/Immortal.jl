module Chronometer
    using Dates
    export message_with_time

    """Функция, которая возвращает строку, которая сформирована 
    из служебных символов, и времени вызова.

    message: сообщение, которое требуется обогатить датой и временем
    """
    function message_with_time(message)::String
        @info "Вызвана функция хронометра"

        @debug "Параметры вызова функции:"
        @debug "> сообщение, которое требуется передать" message

        return string("<", Dates.now(), "> ", message)
    end
end
