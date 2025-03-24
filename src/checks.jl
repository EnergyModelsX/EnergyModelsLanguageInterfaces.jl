"""
    EMB.check_node(n::WindPower, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`WindPower`](@ref)* node is valid.

It reuses the standard checks of a `Source` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the data.

## Checks
 - The field `cap` is required to be non-negative (similar to the `Source` check).
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `output` are required to be non-negative
   (similar to the `Source` check).
 - The field `profile` is required to be in the range ``[0, 1]`` for all time steps
   ``t ∈ \\mathcal{T}``.
"""
function EMB.check_node(
    n::WindPower,
    𝒯,
    modeltype::EMB.EnergyModel,
    check_timeprofiles::Bool,
)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    @assert_or_log(
        all(EMR.profile(n, t) ≤ 1 for t ∈ 𝒯),
        "The profile field must be less or equal to 1."
    )
    @assert_or_log(
        all(EMR.profile(n, t) ≥ 0 for t ∈ 𝒯),
        "The profile field must be non-negative."
    )
end
