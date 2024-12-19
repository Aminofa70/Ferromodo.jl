using Ferromodo
using Documenter

DocMeta.setdocmeta!(Ferromodo, :DocTestSetup, :(using Ferromodo); recursive=true)

makedocs(;
    modules=[Ferromodo],
    authors="Aminofa70 <amin.alibakhshi@upm.es> and contributors",
    sitename="Ferromodo.jl",
    format=Documenter.HTML(;
        canonical="https://Aminofa70.github.io/Ferromodo.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Aminofa70/Ferromodo.jl",
    devbranch="main",
)
