# Routes configuration for FeaturePack
# This file is loaded by Rails routes to set up all group and feature routes

FeaturePack.groups.each do |group|
  # Configure group-level routes
  scope group.manifest[:url], as: group.name do
    if group.routes_file.nil?
      raise FeaturePack::Error::NoDataError, 
            "Group '#{group.name}' routes file not found in #{group.metadata_path}"
    end

    draw(group.routes_file)
  end

  # Configure feature-level routes within the group namespace
  namespace group.name, path: group.manifest[:url] do
    group.features.each do |feature|
      scope feature.manifest[:url], as: feature.name do
        if feature.routes_file.nil?
          raise FeaturePack::Error::NoDataError, 
                "Feature '#{feature.name}' routes file not found in #{feature.routes_file_path}"
        end

        draw(feature.routes_file)
      end
    end
  end
end
