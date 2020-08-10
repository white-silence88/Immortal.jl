using Immortal
using Documenter

makedocs(;
    modules=[Immortal],
    authors="Dmitrii Shevelev",
    repo="https://github.com/small-entropy/Immortal.jl/blob/{commit}{path}#L{line}",
    sitename="Immortal.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://small-entropy.github.io/Immortal.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/small-entropy/Immortal.jl",
)
