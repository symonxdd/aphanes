import Link from 'next/link';
import { Footer } from '@/components/Footer';
import { Bullet } from '@/components/Bullet';

export const metadata = {
  title: 'Privacy Policy | webOS Dev Mode Manager',
  description:
    'How webOS Dev Mode Manager handles data. No account, no telemetry, and a closed list of named outbound requests.',
};

/// The Play Store listing and the app's About sheet both point here, so
/// this address is effectively permanent: Play requires a privacy policy
/// URL that does not move.
///
/// Deliberately its own route rather than the anchored section on the
/// home page. Play reviewers, and the Data safety form, expect a page
/// that is only the policy.
/// Both dates are shown. A policy that only says when it last changed
/// leaves a reader unable to tell a long-standing document from one
/// written yesterday, and the first-published date is the part that
/// says which.
const PUBLISHED = '9 September 2026';
const UPDATED = '24 September 2026';

/// Contact address shown in the policy. A privacy policy has to name a
/// way to reach the developer, and Play checks that it does.
///
/// A Cloudflare Email Routing alias on symon.me rather than a real
/// mailbox: Play publishes this address on the store listing, so it is
/// public by design, and an alias can be retired without touching the
/// inbox behind it.
const CONTACT = 'privacy@symon.me';

function Heading({ children }) {
  return (
    <h2 className="mt-14 text-xl font-semibold tracking-tight sm:text-2xl">
      {children}
    </h2>
  );
}

function Body({ children }) {
  return (
    <p className="mt-4 text-[15px] leading-relaxed text-muted-foreground">
      {children}
    </p>
  );
}

function Bullets({ items }) {
  return (
    <ul className="mt-4 space-y-3">
      {items.map((item) => (
        <li
          key={item}
          className="flex gap-3 text-[15px] leading-relaxed text-muted-foreground"
        >
          <Bullet />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

const REQUESTS = [
  {
    what: 'The Homebrew catalog',
    to: 'repo.webosbrew.org',
    when: 'When the catalog screen is opened',
    sends:
      'Nothing about the user or their TVs. It is a plain read of a public file.',
  },
  {
    what: 'A package download',
    to: 'Whichever host the catalog entry names, usually github.com',
    when: 'When an install is started',
    sends:
      'Nothing about the user or their TVs. Downloaded bytes are checked against the SHA-256 hash published in the catalog and refused on a mismatch.',
  },
  {
    what: 'The Developer Mode session check',
    to: 'developer.lge.com, operated by LG Electronics Inc.',
    when: 'When a device detail page is opened',
    sends:
      'The Developer Mode session token read from that TV. This is the only request that carries anything at all.',
  },
  {
    what: 'An installed app’s description (desktop only)',
    to: 'repo.webosbrew.org, and for the images in it, whichever hosts its author put them on, usually github.com',
    when: 'When an installed app’s page is opened, and only while it is shown',
    sends:
      'Nothing about the user or their TVs. It is a plain read of public files.',
  },
  {
    what: 'The update check (desktop only)',
    to: 'github.com, this project’s own repository',
    when: 'When Check for updates is clicked in Settings. Downloading an update, and installing it, each take a further click.',
    sends:
      'Nothing about the user or their TVs. A downloaded update is checked against a signature built into the app and refused on a mismatch.',
  },
];

export default function PrivacyPolicy() {
  return (
    <>
      <header className="border-b border-foreground/5">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-6 py-5">
          <Link href="/" className="flex items-center gap-2.5">
            <img src="/icon.svg" alt="" className="h-7 w-7" />
            <span className="font-semibold tracking-tight">
              webOS Dev Mode Manager
            </span>
          </Link>
          <Link
            href="/"
            className="text-sm text-muted-foreground hover:text-foreground"
          >
            Back
          </Link>
        </div>
      </header>

      <main className="flex-1">
        <div className="mx-auto max-w-3xl px-6 py-16 sm:py-24">
          <p className="text-xs font-medium uppercase tracking-[0.2em] text-accent">
            Privacy
          </p>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
            Privacy Policy
          </h1>
          <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
            This policy covers webOS Dev Mode Manager, both the Android app
            and the Windows desktop app. Where the two differ, it says so.
          </p>

          {/* The package name and the two dates as a labelled row rather
              than trailing the sentence above. An identifier that long
              wraps onto a line of its own anyway, and reads as debris
              when it does; given a label, the same wrap is deliberate. */}
          <dl className="mt-8 grid grid-cols-1 gap-x-10 gap-y-4 border-y border-foreground/10 py-5 sm:grid-cols-3">
            {[
              ['Package name', <code key="pkg">me.symon.aphanes</code>],
              ['First published', PUBLISHED],
              ['Last updated', UPDATED],
            ].map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs font-medium uppercase tracking-widest text-muted-foreground">
                  {label}
                </dt>
                <dd className="mt-1.5 text-sm">{value}</dd>
              </div>
            ))}
          </dl>

          <Heading>The short version</Heading>
          <Body>
            The app has no account, no sign in, no sync and no server of its
            own. It talks directly to the LG webOS TVs that its user has paired
            with it, over the local network. Nothing about a person, a phone or
            a TV is collected, stored remotely, profiled, sold or shared for
            advertising. There is no analytics, no crash reporting and no
            telemetry of any kind.
          </Body>

          <Heading>Who is responsible</Heading>
          <Body>
            The app is developed and published by Symon, an independent
            developer, as a personal project. Questions about this policy can
            go to {CONTACT}.
          </Body>
          <Body>
            The app is not affiliated with, endorsed by, or connected to LG
            Electronics Inc. or the webOS Open Source Edition project.
          </Body>

          <Heading>What stays on the device</Heading>
          <Body>
            The following is created and held on the device only. None of it is
            transmitted anywhere, and none of it is readable by the developer.
          </Body>
          <Bullets
            items={[
              'Paired TVs: their names, their network addresses and their identifiers.',
              'The Developer Mode pairing key and passphrase for each paired TV, held in the Android keystore through encrypted platform storage, or in Windows Credential Manager on desktop.',
              'The Developer Mode session token read from a paired TV.',
              'Cached hardware and firmware details of a paired TV, so a detail page can be shown before the TV answers.',
              'App settings such as the chosen theme and accent color.',
            ]}
          />
          <Body>
            On Android, automatic cloud backup and phone-to-phone transfer are
            switched off for this app, so none of the above is copied off the
            device by Android either. On desktop, everything above other than
            the keys sits in one file in the app’s own data folder on that
            computer.
          </Body>

          <Heading>What leaves the device</Heading>
          <Body>
            Two kinds of traffic exist. The first is between the app and the
            paired TV itself, over the local network, using SSH. That traffic
            carries device credentials and commands, it never passes through
            any third party, and the TV is the user’s own hardware.
          </Body>
          <Body>
            The second is a closed list of requests to the public internet:
            three on both apps, and two more on desktop only. Each runs only
            because a person opened the screen or
            started the action that needs it. None runs in the background, on a
            schedule, or at launch.
          </Body>
          <div className="mt-6 space-y-4">
            {REQUESTS.map(({ what, to, when, sends }) => (
              <div
                key={what}
                className="rounded-xl border border-foreground/10 p-5"
              >
                <p className="text-sm font-medium">{what}</p>
                <p className="mt-2 text-xs text-muted-foreground">To: {to}</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  When: {when}
                </p>
                <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
                  Sends: {sends}
                </p>
              </div>
            ))}
          </div>
          <Body>
            The session check is worth stating plainly. A Developer Mode
            session belongs to LG: they issue it, they time it, and their
            server is the only thing that knows how much of it remains. The TV
            cannot answer the question, so there is no local alternative. The
            token is sent to LG for that one question and for nothing else, and
            it is sent over HTTPS. What LG does with a request to their own
            service is governed by LG’s privacy policy, not this one.
          </Body>
          <Body>
            Any request necessarily reveals the device’s public IP address to
            the host being contacted, as every internet request does. The app
            adds no identifier of its own to these requests.
          </Body>

          <Heading>What is never collected</Heading>
          <Bullets
            items={[
              'No name, email address, phone number or account of any kind.',
              'No location data, precise or approximate.',
              'No contacts, messages, call logs, photos or files beyond a package file the user picks deliberately.',
              'No advertising identifier, and no advertising of any kind.',
              'No analytics, usage statistics, crash reports or performance telemetry.',
              'No third-party software development kits that collect data.',
            ]}
          />

          <Heading>Permissions</Heading>
          <Body>
            The Android app requests one Android permission: internet access.
            It is needed to reach a paired TV on the local network and to make
            the requests listed above. The app requests no location,
            contacts, storage, camera, microphone or telephony permissions.
            Choosing a local package file to install uses the Android system
            file picker, which grants access to that one chosen file without a
            storage permission. The desktop app runs as an ordinary Windows
            program, asks for no special permissions, and uses the Windows file
            picker the same way.
          </Body>

          <Heading>Retention and deletion</Heading>
          <Body>
            Because nothing is collected or held remotely, there is nothing
            stored elsewhere to request the deletion of. Data held on the
            device is removed by the user directly: deleting a paired device
            from the app removes that device’s credentials, cached details and
            session token immediately. Uninstalling the Android app removes
            everything it stored. On desktop, removing a paired device clears
            its keys from Windows Credential Manager, and the uninstaller offers
            to delete the rest of the app’s data.
          </Body>

          <Heading>Children</Heading>
          <Body>
            The app is a developer tool for managing television hardware. It is
            not directed at children, and it neither seeks nor knowingly holds
            information about them.
          </Body>

          <Heading>Changes to this policy</Heading>
          <Body>
            If the list of outbound requests above ever changes, this page
            changes with it in the same release, and the date at the top is
            updated. Material changes will also be noted in the app’s
            changelog.
          </Body>

          <Heading>Contact</Heading>
          <Body>
            Questions, corrections or concerns about this policy can go to{' '}
            {CONTACT}, or be raised as an issue on the project’s public
            repository.
          </Body>
        </div>
      </main>

      <Footer />
    </>
  );
}
