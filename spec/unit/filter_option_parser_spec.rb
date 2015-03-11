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

require_relative "spec_helper"

describe FilterOptionParser do
  subject { FilterOptionParser }

  describe ".to_filter" do
    before(:each) do
      allow(Filter).to receive(:from_default_definition).and_return(Filter.new)
    end

    context "with the global --exclude option" do
      it "handles simple filter definitions" do
        filter = subject.to_filter("inspect", {}, { "exclude" => "/unmanaged_files/files/name=/foo" })

        expect(filter.to_array).to match_array([
          "/unmanaged_files/files/name=/foo"
        ])
      end

      it "handles multiple filter definitions" do
        filter = subject.to_filter("inspect", {},
          { "exclude" => "/unmanaged_files/files/name=/foo,/changed_managed_files/files/name=/bar" })

        expect(filter.to_array).to match_array([
          "/unmanaged_files/files/name=/foo",
          "/changed_managed_files/files/name=/bar"
        ])
      end

      it "handles multiple filter definitions with array matchers" do
        filter = subject.to_filter("inspect", {},
          { "exclude" => "\"/changed_managed_files/files/change=md5,size\",/changed_managed_files/files/name=/bar" })

        expect(filter.to_array).to match_array([
          "/changed_managed_files/files/change=md5,size",
          "/changed_managed_files/files/name=/bar"
        ])
      end
    end

    context "with the --skip-files option" do
      it "it reads a list of excluded files from a file" do
        FileUtils.mkdir_p("/tmp")
        exclude_file = Tempfile.new("exclude_file")
        begin
          File.write(exclude_file.path, "/foo/bar\n/baz \n")

          filter = subject.to_filter("inspect", { "skip-files" => "/foo,@#{exclude_file.path}" }, {})
          expect(filter.to_array).to match_array([
            "/unmanaged_files/files/name=/foo",
            "/unmanaged_files/files/name=/foo/bar",
            "/unmanaged_files/files/name=/baz"
          ])
        ensure
          exclude_file.close
          exclude_file.unlink
        end
      end

      it "handles simple excludes" do
        filter = subject.to_filter("inspect", {"skip-files" => "/foo" }, {})

        expect(filter.to_array).to eq(["/unmanaged_files/files/name=/foo"])
      end

      it "handles lists of excludes" do
        filter = subject.to_filter("inspect", { "skip-files" => "/foo,/bar" }, {})

        expect(filter.to_array).to eq([
          "/unmanaged_files/files/name=/foo",
          "/unmanaged_files/files/name=/bar"
        ])
      end

      it "handles escaped commas" do
        filter = subject.to_filter("inspect", { "skip-files" => "/foo,/bar,/file\\,with_comma" }, {})

        expect(filter.to_array).to eq([
          "/unmanaged_files/files/name=/foo",
          "/unmanaged_files/files/name=/bar",
          "/unmanaged_files/files/name=/file,with_comma"
        ])
      end

      it "handles escaped @s" do
        filter = subject.to_filter("inspect", { "skip-files" => "\\@file_with_at,/foo" }, {})

        expect(filter.to_array).to eq([
          "/unmanaged_files/files/name=@file_with_at",
          "/unmanaged_files/files/name=/foo"
        ])
      end

      it "fails gracefully when a filter file does not exist" do
        expect {
          subject.to_filter("inspect", { "skip-files" => "@does_not_exist" }, {})
        }.to raise_error(Machinery::Errors::MachineryError, /does not exist/)
      end

      it "expands filter file paths" do
        FileUtils.mkdir_p("/tmp")
        File.write("/tmp/filter_file", "/foo")

        filter = subject.to_filter("inspect", { "skip-files" => "@/tmp/foo/../filter_file" }, {})
        expect(filter.to_array).to eq(["/unmanaged_files/files/name=/foo"])
      end

      it "ignores empty filters" do
        FileUtils.mkdir_p("/tmp")
        File.write("/tmp/filter_file", "/foo\n\n/bar\n")
        filter = subject.to_filter("inspect", { "skip-files" => "@/tmp/filter_file" }, {})

        expect(filter.to_array).to eq([
          "/unmanaged_files/files/name=/foo",
          "/unmanaged_files/files/name=/bar"
        ])
      end
    end
  end
end
