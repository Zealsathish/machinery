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

# This class takes care of transforming the user-provided filter options into
# actual Filter objects.
class FilterOptionParser
  def self.to_filter(command, options, global_options)
    filter = Filter.from_default_definition(command)

    skip_files = options.delete("skip-files")
    if skip_files
      files = skip_files.split(/(?<!\\),/) # Do not split on escaped commas
      files = files.flat_map do |file|
        if file.start_with?("@")
          filename = File.expand_path(file[1..-1])

          if !File.exists?(filename)
            raise Machinery::Errors::MachineryError.new(
              "The filter file '#{filename}' does not exist."
            )
          end
          File.read(filename).lines.map(&:strip)
        else
          file
        end
      end

      files.reject!(&:empty?) # Ignore empty filters
      files.map! { |file| file.gsub("\\@", "@") } # Unescape escaped @s
      files.map! { |file| file.chomp("/") } # List directories without the trailing /, in order to
                                            # not confuse the unmanaged files inspector
      files.each do |file|
        filter.add_element_filter_from_definition("/unmanaged_files/files/name=#{file}")
      end
    end

    filter
  end
end
