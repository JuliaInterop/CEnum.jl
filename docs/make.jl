using CEnum
using Documenter

makedocs(;
    sitename = "CEnum.jl",
    modules = [CEnum],
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Reference" => "reference.md",
    ],
    checkdocs = :exports,
)

deploydocs(;
    repo = "github.com/JuliaInterop/CEnum.jl.git",
    devbranch = "master",
)
