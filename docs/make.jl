using Documenter
using DocumenterInterLinks
using EnergyModelsBase
using EnergyModelsRenewableProducers
using EnergyModelsHeat
using EnergyModelsLanguageInterfaces
using TimeStruct
using Dates
using Literate

const EMB = EnergyModelsBase
const EMR = EnergyModelsRenewableProducers
const EMLI = EnergyModelsLanguageInterfaces

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp("NEWS.md", news; force = true)

inputfile = joinpath(@__DIR__, "src", "examples", "sampling.jl")
Literate.markdown(inputfile, joinpath(@__DIR__, "src", "examples"))

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
    "EnergyModelsRenewableProducers" => "https://energymodelsx.github.io/EnergyModelsRenewableProducers.jl/stable/",
)

makedocs(
    sitename = "EnergyModelsLanguageInterfaces",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
        ansicolor = true,
    ),
    modules = [EnergyModelsLanguageInterfaces],
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start"=>"manual/quick-start.md",
            "Release notes"=>"manual/NEWS.md",
        ],
        "Nodes" => Any[
            "BioCHP"=>"nodes/biochp.md",
            "WindPower"=>"nodes/windpower.md",
            "PV"=>"nodes/pv.md",
            "PVandCSP"=>"nodes/pvandcsp.md",
            "MultipleBuildingTypes"=>"nodes/multiplebuildingtypes.md",
        ],
        "Resources" => Any["ResourceBio"=>"resources/resourcebio.md"],
        "Utility functions" => Any["Reference"=>"util-fun/reference.md"],
        "How-to" =>
            Any["Contribute"=>"how-to/contribute.md", "Utilize"=>"how-to/utilize.md"],
        "Examples" => Any["Sampling"=>"examples/sampling.md"],
        "Library" => Any[
            "Public"=>"library/public.md",
            "Internals"=>String[
                "library/internals/methods-EMLI.md",
                "library/internals/methods-EMB.md",
                "library/internals/methods-EMR.md",
            ],
        ],
    ],
    plugins = [links],
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsLanguageInterfaces.jl.git",
)
