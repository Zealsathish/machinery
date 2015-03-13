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

describe ConfigFilesInspector do
  describe ".inspect" do
    include FakeFS::SpecHelpers

    let(:name) { "systemname" }
    let(:store) { SystemDescriptionStore.new }
    let(:description) {
      SystemDescription.new(name, store)
    }
    let(:filter) { nil }

    before(:each) do
      create_test_description(json: "{}", name: name, store: store).save
      FakeFS::FileSystem.clone("schema/")
    end

    let(:rpm_qa_output_test1) {
      <<-EOF
texlive-metalogo-2013.72.0.0.12svn18611
psmisc-22.20
texlive-bbcard-2013.72.svn19440
open-iscsi-2.0.873
/etc/iscsi/ifaces/iface.example
/etc/iscsi/iscsid.conf
/usr/lib/systemd/system/iscsi.service
/usr/lib/systemd/system/iscsid.service
apache2-2.4.6
/etc/apache2/charset.conv
/etc/apache2/default-server.conf
/etc/apache2/default-vhost-ssl.conf
/etc/apache2/default-vhost.conf
/etc/apache2/errors.conf
yast2-pkg-bindings-3.1.1
EOF
    }
    let(:rpm_qa_output_test2) {
      <<-EOF
texlive-metalogo-2013.72.0.0.12svn18611
psmisc-22.20
texlive-bbcard-2013.72.svn19440
yast2-pkg-bindings-3.1.1
xml-commons-1.3.04
/etc/java/resolver/CatalogManager.properties
EOF
    }
    let(:rpm_v_apache_output) {
      <<-EOF
S.5....T.  c /etc/apache2/default-server.conf
..5....T.  c /etc/apache2/listen.conf
S.5....T.  c /etc/sysconfig/SuSEfirewall2.d/services/apache2
missing    c /usr/share/info/dir
S.5....T.    /etc/sysconfig/ignore_me_cause_im_not_a_config_file
.........  c /usr/share/man/man1/time.1.gz (replaced)
EOF
    }
    let(:rpm_v_openiscsi_output) {
      <<-EOF
SM5..UGT.  c /etc/iscsi/iscsid.conf
EOF
    }
    let(:ls_fn_output) {
      <<-EOF
-rw-r--r-- 1 0 0 3763 Mar 27  2013 /etc/apache2/default-server.conf
-rw-r--r-- 1 0 0 1053 Mar 27  2013 /etc/apache2/listen.conf
-rw-r--r-- 1 0 0 361 Mar 27  2013 /etc/sysconfig/SuSEfirewall2.d/services/apache2
-rw-r--r-- 1 0 0 12024 Jun  6  2013 /etc/iscsi/iscsid.conf
EOF
    }
    let(:stat_output) {
      <<-EOF
644:root:root:0:0:/etc/apache2/default-server.conf
6644:root:root:0:0:/etc/apache2/listen.conf
644:root:root:0:0:/etc/sysconfig/SuSEfirewall2.d/services/apache2
4700:nobody:nobody:65534:65533:/etc/iscsi/iscsid.conf
644:root:root:0:0:/usr/share/man/man1/time.1.gz
EOF
    }
    let(:config_paths) {
      [
        "/etc/iscsi/iscsid.conf",
        "/etc/apache2/default-server.conf",
        "/etc/apache2/listen.conf",
        "/etc/sysconfig/SuSEfirewall2.d/services/apache2",
        "/usr/share/man/man1/time.1.gz"
      ]
    }
    let(:base_cmdline) {
      ["rpm", "-V", "--nodeps", "--nodigest", "--nosignature", "--nomtime", "--nolinkto"]
    }

    def expect_requirements(system)
      expect(system).to receive(:check_requirement).with(
        "rpm", "--version"
      )
      expect(system).to receive(:check_requirement).with(
        "stat", "--version"
      )
    end

    def expect_rpm_qa(system,output)
      expect(system).to receive(:run_command).with(
        "rpm", "-qa",
        "--configfiles", "--queryformat",
        "%{NAME}-%{VERSION}\n",
        :stdout => :capture
      ).and_return(output)
    end

    def expect_data_gather_cmds(system,files,stats_output)
      expect(system).to receive(:run_command).with(
        "stat", "--printf", "%a:%U:%G:%u:%g:%n\\n", *files,
        :stdout => :capture
      ).and_return(stats_output)
    end

    def expect_inspect_configfiles(system,extract)
      expect_requirements(system)
      if(extract)
        expect(system).to receive(:check_requirement).with(
          "rsync", "--version"
        )
      end
      expect_rpm_qa(system,rpm_qa_output_test1)
      rpm_test_data = [
        ["apache2-2.4.6", rpm_v_apache_output],
        ["open-iscsi-2.0.873", rpm_v_openiscsi_output]
      ]
      rpm_test_data.each do |pkg_name, output|
        expect(system).to receive(:run_command).with(
          *base_cmdline, pkg_name,
          :stdout => :capture
        ).and_raise(Cheetah::ExecutionFailed.new(nil, nil, output, nil))
      end
      expect_data_gather_cmds(
        system,
        config_paths, stat_output
      )
      if(extract)
        cfdir = File.join(store.description_path(name), "config_files")
        expect(system).to receive(:retrieve_files).with(
          config_paths,
          cfdir
        )
      end
    end

    it "returns data about modified config files when requirements are fulfilled" do
      system = double
      md5_os = ConfigFile.new(
        name:            "",
        package_name:    "apache2",
        package_version: "2.4.6",
        status:          "changed",
        changes:         ["size", "md5", "time"],
        user:            "root",
        group:           "root",
        mode:            "644"
      )

      apache_1 = md5_os.dup
      apache_1.name = "/etc/apache2/default-server.conf"

      apache_2 = md5_os.dup
      apache_2.name = "/etc/apache2/listen.conf"
      apache_2.changes = ["md5", "time"]
      apache_2.mode = "6644"

      apache_3 = md5_os.dup
      apache_3.name = "/etc/sysconfig/SuSEfirewall2.d/services/apache2"

      apache_4 = ConfigFile.new(
        name:            "/usr/share/info/dir",
        package_name:    "apache2",
        package_version: "2.4.6",
        status:          "changed",
        changes:         ["deleted"]
      )
      apache_5 = ConfigFile.new(
        name:            "/usr/share/man/man1/time.1.gz",
        package_name:    "apache2",
        package_version: "2.4.6",
        status:          "changed",
        changes:         ["replaced"],
        user:            "root",
        group:           "root",
        mode:            "644"
      )

      iscsi_1 = md5_os.dup
      iscsi_1.changes = ["size", "mode", "md5", "user", "group", "time"]
      iscsi_1.name = "/etc/iscsi/iscsid.conf"
      iscsi_1.package_name = "open-iscsi"
      iscsi_1.package_version = "2.0.873"
      iscsi_1.user = "nobody"
      iscsi_1.group = "nobody"
      iscsi_1.mode = "4700"

      expected_data = ConfigFilesScope.new(
        extracted: false,
        files: ConfigFileList.new([apache_1, apache_2, iscsi_1, apache_3, apache_4, apache_5])
      )

      expect_inspect_configfiles(system, false)

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter)

      expect(description["config_files"]).to eq(expected_data)
      expect(inspector.summary(description)).to include("6 changed configuration files")
    end

    it "returns empty when no modified config files are there" do
      system = double
      expect_requirements(system)
      expect_rpm_qa(system,rpm_qa_output_test2)
      expect(system).to receive(:run_command).with(
        *base_cmdline, "xml-commons-1.3.04",
        :stdout => :capture
      ).and_return("")

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter)

      expected = ConfigFilesScope.new(
        extracted: false,
        files: ConfigFileList.new()
      )
      expect(description["config_files"]).to eq(expected)
    end

    it "raise an error when requirements are not fulfilled" do
      system = double
      expect(system).to receive(:check_requirement).with(
        "rpm", "--version"
      ).and_raise(Machinery::Errors::MissingRequirement)

      inspector = ConfigFilesInspector.new
      expect{inspector.inspect(system, description, filter)}.to raise_error(
        Machinery::Errors::MissingRequirement)
    end

    it "extracts changed configuration files" do
      system = double
      expect_inspect_configfiles(system, true)

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter, :extract_changed_config_files => true )
      expect(inspector.summary(description)).to include("Extracted 6 changed configuration files")
      cfdir = File.join(store.description_path(name), "config_files")
      expect(File.stat(cfdir).mode & 0777).to eq(0700)
    end

    it "keep permissions on extracted config files dir" do
      system = double
      cfdir = File.join(store.description_path(name), "config_files")
      FileUtils.mkdir_p(cfdir)
      File.chmod(0750,cfdir)
      File.chmod(0750, store.description_path(name))
      expect_inspect_configfiles(system, true)

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter, :extract_changed_config_files => true)
      expect(inspector.summary(description)).to include("Extracted 6 changed configuration files")
      expect(File.stat(cfdir).mode & 0777).to eq(0750)
    end

    it "removes config files on inspect without extraction" do
      system = double
      expect_inspect_configfiles(system, false)

      cfdir = File.join(store.description_path(name), "config_files")
      cfdir_file = File.join(cfdir, "config_file")
      FileUtils.mkdir_p(cfdir)
      FileUtils.touch(cfdir_file)

      expect(File.exists?(cfdir_file)).to be true

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter)

      expect(File.exists?(cfdir_file)).to be false
    end

    it "returns schema compliant data" do
      system = double
      expect_inspect_configfiles(system, true)

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter, extract_changed_config_files: true )

      expect {
        JsonValidator.new(description.to_hash).validate
      }.to_not raise_error
    end

    it "returns sorted data" do
      system = double
      expect_inspect_configfiles(system, true)

      inspector = ConfigFilesInspector.new
      inspector.inspect(system, description, filter, :extract_changed_config_files => true)
      names = description["config_files"].files.map(&:name)

      expect(names).to eq(names.sort)
    end
  end
end
