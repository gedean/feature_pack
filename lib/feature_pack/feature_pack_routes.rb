FeaturePack.groups.each do |group|
  unless group.manifest[:namespace_only]
    # Default 'index' route every group has to have.
    get group.manifest[:url],
        to: "#{group.name.name}#index",
        as: group.name.name

    unless group.routes_file.nil?
      scope group.manifest[:url] do
        draw(group.routes_file)
      end
    end
  end

  namespace group.name, path: group.manifest[:url] do
    group.features.each do |feature|
      scope feature.manifest[:url], as: feature.name.name.pluralize do
        draw(feature.routes_file)
      end
    end
  end
end
