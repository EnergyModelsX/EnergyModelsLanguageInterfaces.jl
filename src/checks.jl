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
    modeltype::EnergyModel,
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
    EMB.check_node(n::MultipleBuildingTypes, 𝒯, ::EnergyModel, ::Bool)

This method checks that the [`MultipleBuildingTypes`](@ref) node is valid.

## Checks
- The field `cap_p` is required to be non-negative for all resources `p`.
- The values of the dictionary `input` are required to be non-negative.
- The sum of the fields `penalty_surplus` and `penalty_deficit` has to be
  non-negative to avoid an infeasible model.
"""
function EMB.check_node(n::MultipleBuildingTypes, 𝒯, ::EnergyModel, ::Bool)
    𝒫 = inputs(n)
    for p ∈ 𝒫
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.capacity(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `cap`"
        )
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.surplus_penalty(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `penalty_surplus`"
        )
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.deficit_penalty(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `penalty_deficit`"
        )
    end
    if isempty(setdiff(𝒫, keys(EMB.capacity(n))))
        @assert_or_log(
            all(EMB.capacity(n, t, p) ≥ 0 for t ∈ 𝒯, p ∈ 𝒫),
            "The capacity must be non-negative."
        )
    end
    @assert_or_log(
        all(inputs(n, p) ≥ 0 for p ∈ 𝒫),
        "The values for the Dictionary `input` must be non-negative."
    )

    if isempty(setdiff(𝒫, keys(EMB.surplus_penalty(n)))) &&
       isempty(setdiff(𝒫, keys(EMB.deficit_penalty(n))))
        @assert_or_log(
            all(
                EMB.surplus_penalty(n, t, p) + EMB.deficit_penalty(n, t, p) ≥ 0 for t ∈ 𝒯,
                p ∈ 𝒫
            ),
            "An inconsistent combination of `penalty_surplus` and `penalty_deficit` leads to an infeasible model."
        )
    end
end

"""
    EMB.check_node(n::CSPandPV, 𝒯, ::EnergyModel, check_timeprofiles::Bool)

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
function EMB.check_node(n::CSPandPV, 𝒯, ::EnergyModel, check_timeprofiles::Bool)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    𝒫 = outputs(n)
    for p ∈ 𝒫
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.capacity(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `cap`"
        )
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.opex_fixed(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `opex_fixed`"
        )
        @assert_or_log(
            isempty(setdiff([p], keys(EMB.opex_var(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `opex_var`"
        )
        @assert_or_log(
            isempty(setdiff([p], keys(EMR.profile(n)))),
            "Resource $(p) is not included in the dictionary corresponding to the field `profile`"
        )
    end

    if isempty(setdiff(𝒫, keys(EMB.capacity(n))))
        @assert_or_log(
            all(EMB.capacity(n, t, p) ≥ 0 for t ∈ 𝒯, p ∈ 𝒫),
            "The capacity must be non-negative."
        )
    end
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
    if isempty(setdiff(𝒫, keys(EMB.opex_fixed(n)))) &&
       all(EMB.check_strategic_profile(EMB.opex_fixed(n, p), message) for p ∈ 𝒫)
        # Check that the value is positive in all cases
        @assert_or_log(
            all(EMB.opex_fixed(n, t_inv, p) ≥ 0 for t_inv ∈ 𝒯ᴵⁿᵛ, p ∈ 𝒫),
            "The fixed OPEX must be non-negative."
        )
    end

    if isempty(setdiff(𝒫, keys(EMR.profile(n))))
        @assert_or_log(
            all(EMR.profile(n, t, p) ≤ 1 for t ∈ 𝒯, p ∈ 𝒫),
            "The profile field must be less or equal to 1."
        )
        @assert_or_log(
            all(EMR.profile(n, t, p) ≥ 0 for t ∈ 𝒯, p ∈ 𝒫),
            "The profile field must be non-negative."
        )
    end
end

"""
    check_node(n::BioCHP, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`BioCHP`](@ref)* node is valid.

## Checks
- The output resources must include `electricity_resource`.
- The field `cap` is required to be non-negative.
- The values of the dictionary `input` are required to be non-negative.
- The values of the dictionary `output` are required to be non-negative.
- The value of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  [`check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`](@extref EnergyModelsBase.check_fixed_opex).
"""
function EMB.check_node(n::BioCHP, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    𝒫 = outputs(n)
    @assert_or_log(
        electricity_resource(n) in 𝒫,
        "The output resources must include `electricity_resource`."
    )
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
end
