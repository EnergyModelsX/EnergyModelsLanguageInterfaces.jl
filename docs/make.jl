using Documenter
using EnergyModelsUtilities

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
if isfile(news)
    rm(news)
end
cp("NEWS.md", news)

DocMeta.setdocmeta!(
    EnergyModelsUtilities, :DocTestSetup, :(using EnergyModelsUtilities); recursive=true
)

makedocs(;
    sitename="EnergyModelsUtilities.jl",
    repo="https://gitlab.sintef.no/idesignres/wp-2/energymodelsutilities.jl/blob/{commit}{path}#{line}",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://idesignres.pages.sintef.no/energymodelsutilities.jl/",
        edit_link="main",
        assets=String[],
    ),
    modules=[EnergyModelsUtilities],
    pages=[
        "Home" => "index.md",
        "Manual" => Any[
            "Philosophy" => "manual/philosophy.md", "Release notes" => "manual/NEWS.md"
        ],
        "How-to" => Any["Call external functions" => "how-to/call_external_functions.md",],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => Any["Reference" => "library/internals/reference.md",],
        ],
    ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
