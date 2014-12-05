# Copyright (c) 2013-2014 SUSE LLC
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

describe Machinery::ScopeMixin do
  class SimpleScope < Machinery::Object
    include Machinery::ScopeMixin
  end
  class MoreComplexScope < Machinery::Object
    include Machinery::ScopeMixin
  end

  subject { SimpleScope.new }

  it "provides accessors for timestamp and hostname to a simple scope" do
    mytime = Time.now.utc.iso8601
    host = "192.168.122.216"

    expect(subject.meta).to be(nil)

    subject.set_metadata(mytime, host)

    t = Time.utc(subject.meta.modified)
    expect(t.utc?).to eq(true)
    expect(subject.meta.modified).to eq(mytime)
    expect(subject.meta.hostname).to eq(host)
  end

  describe "#scope_name" do
    example { expect(subject.scope_name).to eq("simple") }
    example { expect(MoreComplexScope.new.scope_name).to eq("more_complex") }
  end

  it "lists all scopes" do
    expect(Machinery::ScopeMixin.all_scopes).to include(SimpleScope)
    expect(Machinery::ScopeMixin.all_scopes).to include(MoreComplexScope)
  end

  it "lists only scopes" do
    Machinery::ScopeMixin.all_scopes.each do |scope|
      expect(scope.included_modules).to include(Machinery::ScopeMixin)
    end
  end

  describe "#is_extractable?" do
    before(:each) do
      stub_const("SystemDescription::EXTRACTABLE_SCOPES", ["simple"])
    end

    example { expect(subject.is_extractable?).to be(true) }
    example { expect(MoreComplexScope.new.is_extractable?).to be(false) }
  end

  describe "#class_for" do
    it "returns simple scope" do
      expect(Machinery::ScopeMixin.class_for("simple")).to be(SimpleScope)
    end

    it "returns complex scope" do
      expect(Machinery::ScopeMixin.class_for("more_complex")).to be(MoreComplexScope)
    end
  end
end
