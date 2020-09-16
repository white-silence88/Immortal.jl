module Utils
    include("./src/Chronometer.jl")
    import .Chronometer

    include("./src/FileReader.jl")
    import .FileReader

    include("./src/ConfigReader.jl")
    import .ConfigReader

    include("./src/Getters.jl")
    import .Getters

    include("./src/Declares.jl")
    import .Declares
end