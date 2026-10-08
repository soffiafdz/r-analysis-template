# Style

The look of every report, figure, table and slide deck. GUIDE.md section 8
says how to build them; this page says what they look like.

## Colours

Colours have one of two jobs, and a colour never does both:

- **Brand colours** frame the slides: labels, bars, rules. They come from
  the institutions whose logos are on the title page.
- **Data colours** stand for something: a group, a predictor, a measure.
  They live in `manuscript_colors()` and appear in figures and on cards
  that stand for a group.

### Brand

McGill red leads; the Douglas Research Centre and the StoP-AD Centre give
the secondary colours. For another affiliation, change the variables at the
top of `reports-src/slides.scss` and the files in `reports-src/logos/`.

| Token | Hex | Source | Used for |
|---|---|---|---|
| McGill red | `#ED1B2F` | McGill | main accent: eyebrows, the bar on the title page and dividers, table header rules, `.red` cards, `.accent`, the progress bar |
| StoP-AD teal | `#1A6C7A` | centre-stopad.com | second accent: note bars, `.teal` cards |
| Douglas blue | `#177DB3` | douglas.research.mcgill.ca | links |
| Douglas navy | `#102E71` | Douglas Research Centre logo | not on slides: it is 4.9 from the `male` colour |
| Ink | `#1A1A1A` | | text, headings, numbers |
| Soft ink | `#4A4A4A` | | subtitles, the lead sentence |
| Muted | `#5C5C5C` | | units, captions, bylines, slide numbers |
| Rule | `#D9D9D9` | | table row lines |
| Panel | `#F5F5F5` | | card and note backgrounds |

Backgrounds are white. Bold text stays in ink; one phrase per slide at most
may be set in red with `.accent`.

### Data

- Every group, predictor or measure has one named entry in
  `manuscript_colors()`, taken from Paul Tol's colourblind-safe palettes
  (`get_palette("tol_bright")`, `"tol_muted"`). The same group has the same
  colour in every figure, and on slide cards.
- Sex keeps `female` `#8B0000` and `male` `#191970`.
- A data colour is at least 15 away from every brand colour on the same
  slides, measured as the distance in OKLab times 100. Below that, a reader
  takes the frame for data. Tol's red `#EE6677` (10.9 from McGill red) and
  orange `#EE7733` (13.8) fail; so does Douglas navy against `male` (4.9).
  To check a pair:

  ```r
  ok.mat <- farver::convert_colour(
    farver::decode_colour(c("#ED1B2F", "#EE6677")), "rgb", "oklab"
  )
  100 * dist(ok.mat)
  ```

  When a project's data palette is fixed by a paper and fails against a
  brand colour, that colour stays off every slide that shows the group,
  and the README says so under "Project notes".
- A colour used for text, such as a direct label on a line, needs at least
  3:1 contrast on white. Tol's bright yellow `#CCBB44` (1.9:1) is replaced
  by his dark yellow `#997700` when it labels anything.
- Lines and bands can use the full palette; colour is never the only
  encoding where a label can be added.

## Type

| Output | Font | Sizes |
|---|---|---|
| PDF (xelatex) | Libertinus Serif, Libertinus Sans headings | 10 pt body; tables via `style_pdf_table.fn()` |
| HTML slides | Source Sans Pro (shipped with Quarto), then Helvetica Neue, Arial | 34 px root; titles 1.45 em bold; eyebrows 0.5 em, capitals, spaced |
| PowerPoint | Arial | titles 26 pt bold, body 18 pt, notes 14 pt |
| Figures | ggplot2 default sans | `theme_publication()` base size 10 to 12; slide versions 20 |

## Figures

- `theme_publication()` with `use_markdown = TRUE`. Manuscript figures carry
  a bold title ending in a full stop, a subtitle with the sample, and a
  caption with the details, wrapped with `wrap_text()`.
- Lines are labelled directly where possible instead of in a legend.
- Slide versions have no title, subtitle or caption, 16:9, larger text
  (GUIDE.md section 5). The line under them on the slide gives the sample
  size, the interval type and what the sign of an effect means.
- Significance is shown by the marks (filled for significant, hollow for
  not), not by colour alone or only in the text.

## Tables

- gt, styled with `style_manuscript_table()`; `style_screen_table.fn()` for
  HTML, `style_pdf_table.fn()` in PDFs.
- Long row labels are shortened, not set in smaller type.
- Differences come with confidence intervals; p-values only where a test is
  informative, with the reason in the caption where they are left out.

## Captions and text

- Captions start with a bold title of 3 to 8 words ending in a full stop,
  then the details.
- No em-dashes; no stock openers ("Of note", "It is worth noting").
- Numbers in text, captions and slides come from the environment file.

## Slides

### Layout (HTML, `reports-src/slides.scss`)

- **Title page:** a red bar beside an eyebrow (event and date), the title,
  a subtitle and a byline (author, lab, institution). The logos sit along
  the bottom: McGill (white wordmark on a red box), the Douglas Research
  Centre and the StoP-AD Centre. A closing slide, if there is one, uses the
  same layout.
- **Content slides:** a red eyebrow names the part of the talk; the title
  below it, bold and in ink, with no rule, states the slide's message.
- **Dividers** between parts: eyebrow, a large title and one line, beside
  the red bar.
- **Number cards:** grey panel, coloured top bar, bold ink title, large
  ink value, muted unit, one line of detail. Titles, values and details
  line up across a row even when one title wraps.
- **Notes:** grey panel with a teal bar, for one or two sentences.
- **Tables:** centred, 0.85 em, red header rule, light row lines, row labels
  left and values centred.
- One small muted line under a figure or table.
- One message per slide. Numbers go on cards or in tables rather than in
  sentences. Three or more caveats get a slide of their own; one or two go
  in a note on the slide they qualify.

### Card colours

- A card that stands for a group takes the group's colour from
  `manuscript_colors()` and holds only that group's numbers.
- Every other card is `.red`. `.teal` marks the second of two kinds of card
  being contrasted (the error and the check, say), on a slide without group
  cards.
- Group cards and brand cards never share a row.

### Card text

At 1600 by 900 pixels, three cards to a row:

- **Title:** one line, about 25 characters.
- **Value:** up to about 8 characters (`64%`, `4/6`, `0.38`), on one line.
  The value does not wrap; a longer one runs out of the card, where the
  screenshot check catches it. A comparison goes in the detail line
  ("was 41%"), never next to the value.
- **Unit:** a few words. **Detail:** one line.
- Four cards to a row: about two thirds of each.

### Faults and their fixes

Each fault below has turned up in a real deck.

| Fault | Example | Fix |
|---|---|---|
| A line breaks inside a value or a short label | "64%" over "was 41%"; "group B 52%" over "→ 37%" | The value alone in `.big`; the comparison in the detail line; titles that fit on one line |
| A statement that carries no information | "1,204 of 1,204" | "Every participant" or "100%"; leave out what the reader already assumes |
| Small, left-aligned tables | | The theme centres tables at 0.85 em; split a long table rather than shrink it |
| Implementation detail | The list of scripts that were re-run | Name the analyses; scripts and file names belong in the README or the audit document |
| Topic titles | "Results", "Check 2" | The title states the finding; the eyebrow names the part |
| A loose or loaded term | "glitch" for "scored with last year's weights" | Name the thing exactly in the title, and use that term all through |
| One thing under several names or formats | "raw" and "unadjusted"; "4 of 6" and "4/6"; one decimal here, two there | One term per thing; "4/6" in tables and cards, "4 of 6" in prose; the same decimals for the same quantity; a true minus sign (−) |
| Colour that contradicts the content | A card in the treated group's colour showing the control group's numbers; a brand colour beside a similar data colour | The card colour rules; 15 apart between brand and data colours |
| Group order changes between slides | Controls first in a table, treated first in the figure | One order for cards, tables, legends and facets |
| Sample sizes that are never explained | 412 on one slide, 397 on the next | A line on where each sample comes from the first time it appears; N under every figure |
| A figure that needs the speaker | No interval type, no direction of effect, significance only in the text | The line under the figure (Figures, above); filled and hollow marks |
| Thin slides | A slide holding one sentence | Merge it into the slide it qualifies, as a note |
| Invented specifics | Owners and dates in "next steps" that nobody agreed | Decisions as open questions; only facts from the data or from the people concerned |
| Unexpanded abbreviations | "NBA" for *Neurobiology of Aging* | Spell out on first use; journal names in full |

### Checking a deck

1. Render it, then screenshot every slide and look at each image for
   overflow, broken lines, misalignment, collisions and empty space:

   ```sh
   reports-src/screenshot_slides.sh outputs/reports/slides.html <dir>
   ```

2. Read the deck once as someone who has not seen the work, with the table
   above; a colleague's first read is better still.
3. After each fix, render and screenshot again.

### PowerPoint (`reports-src/slides-reference.pptx`)

The same palette on Arial: a title slide with the red bar and the logos,
bold ink titles, tables in place of cards, and notes in small grey text
under the table or figure.

### Logos

`reports-src/logos/` holds the logos, with their sources in
`SOURCES.md`. They are trademarks of their institutions and are not covered
by the template's licence; use them as the institutions' own pages show
them.
