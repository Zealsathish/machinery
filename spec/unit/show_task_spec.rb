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


describe ShowTask, "#show" do
  capture_machinery_output

  let(:show_task) { ShowTask.new }
  let(:system_description) {
    SystemDescription.new("foo", SystemDescriptionMemoryStore.new)
  }
  let(:description_with_packages) {
    create_test_description(json: <<-EOF)
      {
        "packages": []
      }
    EOF
  }

  it "runs the proper renderer when a scope is given" do
    renderer = double
    expect(renderer).to receive(:render).and_return("bar")
    expect(Renderer).to receive(:for).with("foo").and_return(renderer)

    show_task.show(system_description, ["foo"], Filter.new, no_pager: true)
  end

  it "prints scopes missing from the system description" do
    scope = "packages"
    show_task.show(system_description, [scope], Filter.new, no_pager: true)

    expect(captured_machinery_output).to include("requested scopes were not inspected")
    expect(captured_machinery_output).to include("packages")
  end

  it "does not show a message about missing scopes if there are none" do
    scope = "packages"
    show_task.show(description_with_packages, [scope], Filter.new, no_pager: true)

    expect(captured_machinery_output).to_not include("requested scopes were not inspected")
    expect(captured_machinery_output).to_not include("packages")
  end

  it "opens the system description in the web browser" do
    expect(Html).to receive(:generate)
    expect(LocalSystem).to receive(:validate_existence_of_package).with("xdg-utils")
    html_path = SystemDescriptionStore.new.html_path(system_description.name)
    expect(Cheetah).to receive(:run).with("xdg-open", html_path)

    show_task.show(system_description, ["foo"], Filter.new, show_html: true)
  end

end
