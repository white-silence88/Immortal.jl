module Chronometer
    using Dates
    export message_with_time

    """
        Функция, которая возвращает строку, которая сформирована из служебных
        символов, и времени вызова.
    """
    function message_with_time(message)::String
        return string("<", Dates.now(), "> ", message)
    end
end
