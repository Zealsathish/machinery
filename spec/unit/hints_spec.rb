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

require_relative "spec_helper"

describe Hint do
  def enable_hints(enabled)
    allow(Machinery::Config).to receive(:new).and_return(double(hints: enabled))
  end

  describe ".print" do
    capture_machinery_output

    it "shows the hint when hints are enabled" do
      enable_hints(true)
      Hint.print(:get_started)
      expect(captured_machinery_output).to include(
        "Hint: You can get started by inspecting a system. Run:"
      )
    end

    it "returns an empty string if hints are disabled" do
      enable_hints(false)
      Hint.print(:get_started)
      expect(captured_machinery_output).not_to include(
        "Hint: You can get started by inspecting a system. Run:"
      )
    end

    it "shows expanded hint" do
      enable_hints(true)
      Hint.print(:do_complete_inspection, name: "bar", host: "foo")
      expect(captured_machinery_output).to match(
        "Hint: To do a full inspection containing all scopes and to extract files run:\n" \
        ".* inspect foo --name bar --extract-files"
      )
    end
  end

  describe ".to_string" do
    it "returns hint as string if hints are enabled" do
      enable_hints(true)
      expect(Hint.to_string(:get_started)).to include(
        "Hint: You can get started by inspecting a system. Run:"
      )
    end

    it "returns hint as string if hints are disabled" do
      enable_hints(false)
      expect(Hint.to_string(:get_started)).to eq("")
    end

    it "returns expanded hint" do
      enable_hints(true)
      expect(Hint.to_string(:do_complete_inspection, name: "bar", host: "foo")).to match(
        "Hint: To do a full inspection containing all scopes and to extract files run:\n" \
        ".* inspect foo --name bar --extract-files"
      )
    end
  end
end
