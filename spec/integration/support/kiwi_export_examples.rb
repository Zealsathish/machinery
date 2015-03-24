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

shared_examples "kiwi export" do
  after(:all) do
    if @machinery.running?
      @machinery.run_command("test -d /tmp/jeos-kiwi && rm -r /tmp/jeos-kiwi")
    end
  end

  describe "export-kiwi" do
    it "creates a kiwi description" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"),
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )

      measure("export to kiwi") do
        @machinery.run_command(
          "#{machinery_command} export-kiwi jeos --kiwi-dir=/tmp --force",
          as: machinery_config[:owner]
        )
      end

      file_list = @machinery.run_command(
        "ls /tmp/jeos-kiwi",
        stdout: :capture,
        as: machinery_config[:owner]
      ).split("\n")
      expect(file_list).to match_array(["README.md", "config.sh", "config.xml", "root"])
    end

    it "generates a proper config.sh" do
      expected = File.read(File.join(Machinery::ROOT, "spec", "data", "export-kiwi", "config.sh"))
      actual = @machinery.run_command(
        "cat /tmp/jeos-kiwi/config.sh",
        stdout: :capture,
        as: machinery_config[:owner]
      )
      expect(actual).to eq(expected)
    end

    it "generates a proper config.xml" do
      expected = File.read(File.join(Machinery::ROOT, "spec", "data", "export-kiwi", "config.xml"))
      actual = @machinery.run_command(
        "cat /tmp/jeos-kiwi/config.xml",
        stdout: :capture,
        as: machinery_config[:owner]
      )

      expect(actual).to eq(expected)
    end

    it "generates a proper root tree" do
      expected = File.
        read(File.join(Machinery::ROOT, "spec", "data", "export-kiwi", "root"))
      actual = @machinery.run_command(
        "ls -1R --time-style=+ /tmp/jeos-kiwi/root",
        stdout: :capture,
        as: machinery_config[:owner]
      )
      expect(actual).to eq(expected)
    end
  end
end
