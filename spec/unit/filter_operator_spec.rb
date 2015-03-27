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

describe FilterOperator do
  describe ".new" do
    it "returns the operator for known operators" do
      expect(FilterOperator.new("=")).to eq(:==)
      expect(FilterOperator.new(:==)).to eq(:==)
    end

    it "raises an exception unknown operators" do
      expect {
        FilterOperator.new(">=")
      }.to raise_error(Machinery::Errors::InvalidFilter)
      expect {
        FilterOperator.new(:>=)
      }.to raise_error(Machinery::Errors::InvalidFilter)
    end
  end

  describe ".to_string" do
    it "returns the operator for known operators" do
      expect(FilterOperator.to_string(:==)).to eq("=")
    end

    it "raises an exception unknown operators" do
      expect {
        FilterOperator.to_string(:>=)
      }.to raise_error(Machinery::Errors::InvalidFilter)
    end
  end
end
