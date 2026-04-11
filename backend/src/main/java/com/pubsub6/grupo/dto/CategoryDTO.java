package com.pubsub6.grupo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record CategoryDTO(
        String id, String name,
        @JsonProperty("sub_category") SubCategoryDTO subCategory
) {}
