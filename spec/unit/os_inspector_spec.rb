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

describe OsInspector do
  include FakeFS::SpecHelpers

  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }
  let(:system) { LocalSystem.new }
  subject(:inspector) { OsInspector.new }

  before(:each) do
    Dir.mkdir("/etc")
  end

  describe "#get_arch" do
    it "gets the architecture of the inspected system" do
      result = "x86_64"

      expect(system).to receive(:run_command).with(
        "uname", "-m", stdout: :capture).and_return(result)
      expect(inspector.get_arch(system)).to eq(result)
    end
  end

  describe "#get_os_from_os_release" do
    it "gets os info from os-release file" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/os-release",
        "/etc/os-release")

      os = inspector.send(:get_os_from_os_release, system)

      expect(os).to eq(
        OsScope.new(
          name: "openSUSE 13.1 (Bottle)",
          version: "13.1 (Bottle)"
        )
      )
    end
  end

  describe "#get_os_from_suse_release" do
    it "gets os info from SuSE-release file" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")
      os = inspector.send(:get_os_from_suse_release, system)

      expect(os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(os.version).to eq "11 SP3"
    end
  end

  describe "#get_os_from_redhat_release" do
    it "gets os info from SuSE-release file" do
      FakeFS::FileSystem.clone("spec/data/os/rhel6/etc/redhat-release",
        "/etc/redhat-release")
      os = inspector.send(:get_os_from_redhat_release, system)

      expect(os.name).to eq "Red Hat Enterprise Linux Server"
      expect(os.version).to eq "6.5 (Santiago)"
    end
  end

  describe ".inspect" do
    it "returns data about the operation system on a system with os-release" do
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/os-release",
        "/etc/os-release")
      FakeFS::FileSystem.clone("spec/data/os/openSUSE13.1/etc/issue",
        "/etc/issue")

      expect(inspector).to receive(:get_arch).with(system).and_return("x86_64")

      summary = inspector.inspect(system, description)

      expect(description.os).to eq(
        OsScope.new(
          name: "openSUSE 13.1 (Bottle)",
          version: "13.1 (Bottle)",
          architecture: "x86_64"
        )
      )
      expect(summary).to include("openSUSE")
    end

    it "returns data about the operation system on a system with suse-release" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")

      expect(inspector).to receive(:get_arch).with(system).and_return("x86_64")

      summary = inspector.inspect(system, description)

      expect(description.os.name).to eq "SUSE Linux Enterprise Server 11"
      expect(description.os.version).to eq "11 SP3"
      expect(description.os.architecture).to eq "x86_64"
      expect(summary).to include("SUSE Linux Enterprise Server")
    end

    it "returns data about the operation system on a system with redhat-release" do
      FakeFS::FileSystem.clone("spec/data/os/rhel6/etc/redhat-release",
        "/etc/redhat-release")

      expect(inspector).to receive(:get_arch).with(system).and_return("x86_64")

      summary = inspector.inspect(system, description)

      expect(description.os.name).to eq "Red Hat Enterprise Linux Server"
      expect(description.os.version).to eq "6.5 (Santiago)"
      expect(description.os.architecture).to eq "x86_64"
      expect(summary).to include("Red Hat Enterprise Linux Server")
    end

    it "returns data containing additional version information if available" do
      FakeFS::FileSystem.clone("spec/data/os/SLES12/etc/os-release",
        "/etc/os-release")
      FakeFS::FileSystem.clone("spec/data/os/SLES12/etc/issue",
        "/etc/issue")

      expect(inspector).to receive(:get_arch).with(system).and_return("x86_64")

      inspector.inspect(system, description)

      expect(description.os.version).to eq("12 Beta 1")
    end

    it "returns correct data if additonal version information contains double digits" do
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/SuSE-release",
        "/etc/SuSE-release")
      FakeFS::FileSystem.clone("spec/data/os/SLES11/etc/issue",
        "/etc/issue")

      expect(inspector).to receive(:get_arch).with(system).and_return("x86_64")

      inspector.inspect(system, description)

      expect(description.os.version).to eq("11 SP3 Beta 10")
    end

    it "returns data containing nil when the operation system cannot be determined" do
      inspector.inspect(system, description)

      expect(description.os.name).to eq nil
      expect(description.os.version).to eq nil
      expect(description.os.architecture).to eq nil
    end
  end
end
