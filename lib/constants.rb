# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

module Machinery
  ROOT = File.expand_path("..", File.dirname(__FILE__))
  DEFAULT_CONFIG_DIR = File.join(ENV['HOME'], ".machinery")
  DEFAULT_LOG_FILE = File.join(DEFAULT_CONFIG_DIR, "machinery.log")
  DEFAULT_CONFIG_FILE = File.join(DEFAULT_CONFIG_DIR, "machinery.config")
  IMAGE_META_DATA_FILE = "machinery.meta"
end
