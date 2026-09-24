require "application_system_test_case"

class LaunchRegistrationsTest < ApplicationSystemTestCase
  setup do
    @admin = User.create!(
      email: "launch-registration-system@example.com",
      first_name: "Launch",
      last_name: "Admin",
      role: "Member",
      admin: true
    )
    @campaign = RegistrationCampaign.create!(conference: conferences(:one), created_by: @admin)
  end

  test "uses effective viewport centering styles without horizontal overflow" do
    visit launch_registration_path(@campaign.raw_token)

    assert_selector ".launch-registration-page"
    assert_selector "input[type=submit][value='Send activation link']"

    layout = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const pageLayout = document.querySelector(".launch-registration-page");
        const card = pageLayout.querySelector(":scope > div");
        const styles = window.getComputedStyle(pageLayout);
        const cardStyles = window.getComputedStyle(card);

        return {
          display: styles.display,
          alignItems: styles.alignItems,
          justifyContent: styles.justifyContent,
          paddingLeft: Number.parseFloat(styles.paddingLeft),
          minHeight: Number.parseFloat(styles.minHeight),
          viewportHeight: window.innerHeight,
          cardMaxWidth: Number.parseFloat(cardStyles.maxWidth),
          cardWidth: card.getBoundingClientRect().width,
          horizontalOverflow: document.documentElement.scrollWidth > window.innerWidth
        };
      })()
    JAVASCRIPT

    assert_equal "flex", layout.fetch("display")
    assert_equal "center", layout.fetch("alignItems")
    assert_equal "center", layout.fetch("justifyContent")
    assert_operator layout.fetch("paddingLeft"), :>, 0
    assert_operator layout.fetch("minHeight"), :>=, layout.fetch("viewportHeight")
    assert_operator layout.fetch("cardWidth"), :<=, layout.fetch("cardMaxWidth")
    assert_not layout.fetch("horizontalOverflow")

    page.current_window.resize_to(390, 400)
    submit_visible = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const submit = document.querySelector("input[type=submit]");
        submit.scrollIntoView({ block: "nearest" });
        const bounds = submit.getBoundingClientRect();

        return bounds.top >= 0 && bounds.bottom <= window.innerHeight &&
          document.documentElement.scrollWidth <= window.innerWidth;
      })()
    JAVASCRIPT

    assert submit_visible
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
