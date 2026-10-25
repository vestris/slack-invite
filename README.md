Slack Invite Automation
=======================

[![lint](https://github.com/vestris/slack-invite/actions/workflows/lint.yml/badge.svg)](https://github.com/vestris/slack-invite/actions/workflows/lint.yml)
[![test](https://github.com/vestris/slack-invite/actions/workflows/test.yml/badge.svg)](https://github.com/vestris/slack-invite/actions/workflows/test.yml)

Slack Invite Automation. Hosted at [invite.playplay.io](https://invite.playplay.io/).

## Install

[![Add to Slack](https://platform.slack-edge.com/img/add_to_slack.png)](https://invite.playplay.io)

## Features

* Renders a web page for users to self-invite with a team name, link, and icon.
* Optionally requires approval from an existing admin from within Slack.
* Tells users when they are already members of a team.
* Tells users when they have already been invited and does not resend duplicate invitations.
* The account sending invitations is configurable.

## Website

The responsive website shares navigation, a footer and a fixed warm-orange wavy background across the homepage, expandable help, public invitation form, authorization, billing and privacy pages. The waves stay viewport-sized when help expands. Preserve the existing envelope artwork, OAuth scopes, invitation form IDs and handlers, optional admin approval, two-week trial, $9.99 yearly subscription and privacy-policy text. Generated `/styles.css` includes the content-versioned wave artwork.

The site loads only `public/styles.css.erb` for styling. Retired Agency/Bootstrap CSS and JavaScript, Font Awesome, bundled theme fonts, LESS/Sass sources and unused widget scripts have been removed. Keep the active jQuery, URL parsing, common, registration, authorization, invitation and analytics scripts.

## Links

Everybody seems to struggle with this.

### Similar Products

* ~~[slack-invite-automation](https://github.com/outsideris/slack-invite-automation):~~ requires a legacy test token, however [The creation of legacy test tokens is deprecated | Slack](https://api.slack.com/changelog/2020-02-legacy-test-token-creation-to-retire)
* ~~[PublicSlack](https://publicslack.com):~~ no longer functional (sign-up results in a 404, no Twitter activity since 2018)
* [CommunityInviter](https://communityinviter.com/): similar, but approval outside of Slack

### Blog Posts

* [Using StackStorm to Auto-Invite Users to a Slack Organization](https://stackstorm.com/2015/06/30/using-stackstorm-to-auto-invite-users-to-a-slack-organization)
* [How I hacked Slack into a community platform with Typeform](https://levels.io/slack-typeform-auto-invite-sign-ups/)
* [Programmatic Slack invite in JavaScript and React](https://www.robinwieruch.de/slack-invite-javascript-react/)
* [How to Create a Public Slack Community with Open Invites](https://intoli.com/blog/make-a-public-slack-community/)

## Copyright & License

Copyright [Daniel Doubrovkine, Vestris LLC](https://www.vestris.com), 2019-2022

[MIT License](LICENSE)

Icons made by [Freepik](http://www.freepik.com) from [flaticon.com](https://www.flaticon.com).

### Website caching

Local website assets use `h asset_path('/img/example.png')` in ERB HTML and `asset_path('/img/example.png').to_json` in JavaScript to include a content hash. HTML and generated CSS revalidate with `private, no-cache`, configured centrally through `SlackRubyBotServer.config.server_pages`. Generated CSS also hashes nested artwork, so image-only changes are picked up on reload. Static files retain content ETags and timestamp validation; do not add immutable or long-lived cache policies.
