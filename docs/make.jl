using Documenter
using DocumenterInterLinks
using EnergyModelsBase
using EnergyModelsInvestments
using EnergyModelsUtilities
using TimeStruct
using Literate

const EMB = EnergyModelsBase
const EMI = EnergyModelsInvestments
const EMU = EnergyModelsUtilities

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp("NEWS.md", news; force=true)

inputfile = joinpath(@__DIR__, "src", "examples", "sampling.jl")
Literate.markdown(inputfile, joinpath(@__DIR__, "src", "examples"))

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
    "EnergyModelsInvestments" => "https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/",
)

makedocs(
    sitename="EnergyModelsUtilities",
    repo="https://gitlab.sintef.no/idesignres/wp-2/EnergyModelsUtilities.jl/blob/{commit}{path}#{line}",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://idesignres.pages.sintef.no/wp-2/EnergyModelsUtilities.jl",
        edit_link="main",
        assets=String[],
    ),
    modules=[
        EnergyModelsUtilities,
        isdefined(Base, :get_extension) ? Base.get_extension(EMU, :EMIExt) : EMU.EMIExt,
    ],
    pages=[
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Types for EMX elements" => Any["Reference" => "types/reference.md"],
        "Utility functions" => Any["Reference" => "util-fun/reference.md"],
        "How-to" =>
            Any["Contribute" => "how-to/contribute.md", "Utilize" => "how-to/utilize.md"],
        "Examples" => Any["Sampling" => "examples/sampling.md"],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => String[
                "library/internals/types-EMU.md",
                "library/internals/methods-fields.md",
                "library/internals/methods-EMU.md",
                "library/internals/methods-EMB.md",
            ],
        ],
    ],
    plugins=[links],
)
