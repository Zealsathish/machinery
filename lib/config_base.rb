# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com


# The defaults for machinery's configuration are defined in
# the file 'machinery_config.rb'.

class ConfigBase
  def initialize
    @entries = {}
    @file = ""
    define_entries
    apply_custom_config(@file) if File.exist?(@file)
  end

  def default_config_file(file)
    @file = file
  end

  def entry(key, parameters = {})
    key = normalize_key(key)

    @entries[key] = { value: parameters[:default], description: parameters[:description] }
     create_method(key.to_sym) { get(key) }
     create_method("#{key}=".to_sym) { |value| set(key, value) }
  end

  def define_entries
    raise NotImplementedError.new("No config entries defined for #{self.class}")
  end

  def each(&block)
    @entries.map { |key, value| [unnormalize_key(key), value] }.each(&block)
  end

  def get(key)
    key = normalize_key(key)

    ensure_config_exists(key)
    @entries[key][:value]
  end

  def set(key, value, options = {auto_save: true} )
    key = normalize_key(key)
    ensure_config_exists(key)

    # Check if data type is correct. true and false are not of the same type which makes the check complex
    if value.class != @entries[key][:value].class &&
      ! ( ( value == true || value == false ) && ( @entries[key][:value].class == TrueClass || @entries[key][:value].class == FalseClass ) )
      raise Machinery::Errors::MachineryError.new("The value \"#{value}\" for configuration key \"#{key}\" is of an invalid data type.")
    end

    @entries[key][:value] = value

    save if options[:auto_save]
  end


  private

  def save
    config_table_stripped = {}
    @entries.each do |key,value|
      config_table_stripped[key] = value[:value]
    end

    FileUtils.mkdir_p(Machinery::DEFAULT_CONFIG_DIR)

    begin
      File.write(@file, config_table_stripped.to_yaml)
      Machinery.logger.info("Wrote configuration file \"#{@file}\".")
    rescue => e
      raise Machinery::Errors::MachineryError.new("Could not write configuration file \"#{@file}\": #{e}.")
    end
  end

  def apply_custom_config(file)
    content = read_config_file(file) || []

    content.each do |key, value|
      begin
        set(key, value, :auto_save => false )
      rescue => e
        Machinery::Ui.warn "Warning: The machinery config file \"#{file}\" contains an invalid entry \"#{key}\":\n#{e}"
      end
    end
  end

  def read_config_file(file)
    begin
      content = YAML.load_file(file)
      Machinery.logger.info("Read configuration file \"#{file}\".")
    rescue => e
      Machinery::Ui.warn "Warning: Cannot parse machinery config file \"#{@file}\":\n#{e}"
    end
    content
  end

  def ensure_config_exists(key)
    if @entries[key].nil?
      raise Machinery::Errors::UnknownConfig.new("Unknown configuration key: #{key}")
    end
  end

  def create_method(name, &block)
    self.class.send(:define_method, name, &block)
  end

  def normalize_key(key)
    key.gsub("-", "_")
  end

  def unnormalize_key(key)
    key.gsub("_", "-")
  end
end
