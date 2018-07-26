require 'asset_symlink/version'
require 'asset_symlink/railtie'
require 'fileutils'

module AssetSymlink
  def self.execute(config)
    normalize_configuration(config).each do |private_name, public_name|
      prefix = Rails.application.config.assets.prefix.sub(%r{^/}, '')
      asset = find_asset(private_name)
      digested_path = Rails.root.join('public', prefix, asset)
      public_path = create_public_path!(public_name)
      relative_path = digested_path.relative_path_from(public_path.dirname)
      FileUtils.ln_sf(relative_path, public_path)
    end
  end

  def self.normalize_configuration(config)
    case config
    when Hash
      config
    when String
      { config => config }
    when Array
      config.inject({}) { |a, e| a.merge(normalize_configuration(e)) }
    when NilClass
      {}
    else
      raise ArgumentError, "unexpected item #{config} in config.asset_symlink"
    end
  end

  def self.find_asset(name)
    unless Rails.application.assets.nil?
      return Rails.application.assets.find_asset(name).digest_path
    end
    manifest =
      if Sprockets::Railtie.respond_to?(:build_manifest)
        Sprockets::Railtie.build_manifest(Rails.application)
      else
        Rails.application.assets_manifest
      end
    manifest.assets[name]
  end

  def self.create_public_path!(public_name)
    path = Rails.root.join('public', 'assets', public_name)
    FileUtils.mkdir_p(File.dirname(path)) if File.dirname(public_name) != '.'
    path
  end
end
