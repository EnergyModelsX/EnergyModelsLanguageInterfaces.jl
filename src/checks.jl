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

"""
    EMB.check_node(n::CSPandPV, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`CSPandPV`](@ref)* node is valid.

## Checks
- The field `cap_p` is required to be non-negative for all resources `p`.
- The values of the dictionary `output` are required to be non-negative.
- The value of the field `opex_fixed_p` is required to be non-negative.
- The `opex_fixed_p` time profile cannot have a finer granulation than `StrategicProfile`.

## Conditional checks (if `check_timeprofiles=true`)
- The profiles in `opex_fixed_p` have to have the same length as the number of strategic
  periods.
"""
function EMB.check_node(n::CSPandPV, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    𝒫 = outputs(n)

    @assert_or_log(
        all(EMB.capacity(n, t, p) ≥ 0 for t ∈ 𝒯, p ∈ 𝒫),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        all(outputs(n, p) ≥ 0 for p ∈ 𝒫),
        "The values for the Dictionary `output` must be non-negative."
    )

    # Check fixed OPEX
    if isa(EMB.opex_fixed(n), StrategicProfile) && check_timeprofiles
        for p ∈ 𝒫
            @assert_or_log(
                length(EMB.opex_fixed(n, p).vals) == length(𝒯ᴵⁿᵛ),
                "The timeprofile provided for the field `opex_fixed` does not match the " *
                "strategic structure."
            )
        end
    end

    # Check for potential indexing problems
    message = "are not allowed for the field `opex_fixed`."
    bool_sp = all(EMB.check_strategic_profile(EMB.opex_fixed(n, p), message) for p ∈ 𝒫)

    # Check that the value is positive in all cases
    if bool_sp
        @assert_or_log(
            all(EMB.opex_fixed(n, t_inv, p) ≥ 0 for t_inv ∈ 𝒯ᴵⁿᵛ, p ∈ 𝒫),
            "The fixed OPEX must be non-negative."
        )
    end

    @assert_or_log(
        all(EMR.profile(n, t, p) ≤ 1 for t ∈ 𝒯, p ∈ 𝒫),
        "The profile field must be less or equal to 1."
    )
    @assert_or_log(
        all(EMR.profile(n, t, p) ≥ 0 for t ∈ 𝒯, p ∈ 𝒫),
        "The profile field must be non-negative."
    )
end
