# Style

The look of every report, figure, table and slide deck. GUIDE.md section 8
says how to build them; this page says what they look like.

## Palette

| Token | Hex | Used for |
|---|---|---|
| Ink | `#111111` | text, headings, bold text, numbers |
| Muted | `#5C5C5C` | secondary text: units, captions, notes, dates |
| Dark red | `#8B0000` | accents only: rules under headings and titles, card titles, the title slide's subtitle |
| Midnight blue | `#191970` | second accent: neutral cards, the bar of note boxes |
| Rule | `#DDDDDD` | light dividers |
| Panel | `#F5F5F5` | card and note backgrounds |

Backgrounds are white. Dark red and midnight blue are the `female` and `male`
entries of `manuscript_colors()`, so they also mean sex in figures. Text is
never coloured for emphasis: bold text stays in ink.

## Data colours

- Every group, predictor or measure has one named entry in
  `manuscript_colors()`, taken from Paul Tol's colourblind-safe palettes
  (`get_palette("tol_bright")`, `"tol_muted"`). The same group has the same
  colour in every figure, and on slide cards.
- A colour used for text, such as a direct label on a line, needs at least
  3:1 contrast on white. Tol's bright yellow `#CCBB44` (1.9:1) is replaced by
  his dark yellow `#997700` when it labels anything.
- Lines and bands can use the full palette; colour is never the only
  encoding where a label can be added.

## Type

| Output | Font | Sizes |
|---|---|---|
| PDF (xelatex) | Libertinus Serif, Libertinus Sans headings | 10 pt body; tables via `style_pdf_table.fn()` |
| HTML slides | Helvetica Neue, Arial | 34 px root; headings bold, not uppercase |
| PowerPoint | Arial | titles 26 pt bold, body 18 pt, notes 14 pt |
| Figures | ggplot2 default sans | `theme_publication()` base size 10 to 12; slide versions 20 |

## Figures

- `theme_publication()` with `use_markdown = TRUE`. Manuscript figures carry
  a bold title ending in a full stop, a subtitle with the sample, and a
  caption with the details, wrapped with `wrap_text()`.
- Lines are labelled directly where possible instead of in a legend.
- Slide versions have no title, subtitle or caption, 16:9, larger text
  (GUIDE.md section 5).

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

- **HTML** (`reports-src/slides.scss`): left-aligned black headings over a
  thin dark red rule; a white title slide with a dark red rule and subtitle;
  number cards (grey panel, coloured top bar, dark red title, large ink
  number, muted unit); note boxes with a midnight blue bar; one small muted
  caption line under a figure; dark red progress bar.
- **PowerPoint** (`reports-src/slides-reference.pptx`): the same palette and
  rules on Arial, tables in place of cards, notes in small grey text under
  the table or figure.
- One message per slide; numbers on cards or in tables rather than in
  sentences; caveats on their own slide.
