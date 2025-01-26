FeaturePack.groups.each do |group|
  scope group.manifest[:url], as: group.name do
    raise "Group '#{group.name}' routes file not found in #{group.metadata_path}" if group.routes_file.nil?

    draw(group.routes_file)
  end

  namespace group.name, path: group.manifest[:url] do
    group.features.each do |feature|
      scope feature.manifest[:url], as: feature.name do
        raise "Feature '#{feature.name}' routes file not found in #{feature.routes_file}" if feature.routes_file.nil?

        draw(feature.routes_file)
      end
    end
  end
end
