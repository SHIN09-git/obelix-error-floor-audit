"""Render the completed research note; mathematical expressions remain editable in Markdown."""
from __future__ import annotations

import argparse
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
from matplotlib.font_manager import FontProperties
from matplotlib.figure import Figure
from matplotlib.backends.backend_agg import FigureCanvasAgg
from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Image, KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


def markup(text):
    text = html.escape(text)
    text = re.sub(r"\[([^\]]+)\]\((https://[^\s]+)\)", r'<link href="\2" color="#1c526e">\1</link>', text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`([^`]+)`", r'<font size="8.5">\1</font>', text)
    return text


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "tmp/pdf-build/obelix_error_floor_audit.pdf")
    args = parser.parse_args()
    destination = args.output.resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = ROOT / "tmp/pdfs/obelix_note"
    temporary.mkdir(parents=True, exist_ok=True)
    # Standard PDF fonts avoid any local Windows-font dependency or redistribution.
    body = ParagraphStyle("AuditBody", fontName="Times-Roman", fontSize=10.5, leading=14.2, spaceAfter=7, alignment=0, allowWidows=0, allowOrphans=0)
    heading = ParagraphStyle("AuditHeading", parent=body, fontName="Times-Bold", fontSize=12, leading=15, spaceBefore=12, spaceAfter=7, keepWithNext=True, alignment=0)
    title = ParagraphStyle("AuditTitle", parent=heading, fontSize=19, leading=23, textColor=colors.HexColor("#163f56"), spaceBefore=0, spaceAfter=10)
    table_style = ParagraphStyle("AuditCell", parent=body, fontSize=8.6, leading=10.6, spaceAfter=0, alignment=0)
    doc = SimpleDocTemplate(str(destination), pagesize=(595.276, 841.89), rightMargin=52, leftMargin=52, topMargin=48, bottomMargin=46,
                            title="Repeated-composition dispersion does not identify a universal prediction-error floor", author="JIN HANZHE", subject="Version 1.0.0; AI-assisted methodological audit of OBELiX; not peer reviewed")
    lines = (ROOT / "reports/round11/MANUSCRIPT.md").read_text(encoding="utf-8").splitlines()
    story = []
    paragraph = []
    eq_count = 0
    index = 0

    def flush():
        if paragraph:
            story.append(Paragraph(markup(" ".join(paragraph)), body))
            paragraph.clear()

    while index < len(lines):
        line = lines[index]
        if not line.strip():
            flush()
        elif line.startswith("# "):
            flush()
            story.append(Paragraph(markup(line[2:]), title))
        elif line.startswith("## "):
            flush()
            story.append(Paragraph(markup(line[3:]), heading))
        elif line.strip() == r"\[":
            flush()
            equation = []
            index += 1
            while lines[index].strip() != r"\]":
                equation.append(lines[index])
                index += 1
            eq_count += 1
            path = temporary / f"equation_{eq_count}.png"
            expression = " ".join(equation).replace(r"\le ", r"\leq ")
            figure = Figure(figsize=(.1, .1))
            FigureCanvasAgg(figure)
            figure.text(0, 0, "$" + expression + "$", fontproperties=FontProperties(size=13, math_fontfamily="stix"))
            figure.savefig(path, dpi=260, bbox_inches="tight", pad_inches=.06, facecolor="white")
            with PILImage.open(path) as raster:
                width, height = raster.size
            scale = min(72/260, doc.width/width)
            display = Image(str(path), width=width*scale, height=height*scale)
            display.hAlign = "CENTER"
            story.extend([Spacer(1, 5), display, Spacer(1, 10)])
        elif line.startswith("|"):
            flush()
            records = []
            while index < len(lines) and lines[index].startswith("|"):
                parts = [s.strip() for s in lines[index].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-+:?", s) for s in parts):
                    records.append([Paragraph(markup(s), table_style) for s in parts])
                index += 1
            index -= 1
            widths = [130, 40, 65, 65, 86, doc.width-386]
            table = Table(records, colWidths=widths, repeatRows=1, hAlign="LEFT")
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e9f0f4")),
                ("LINEABOVE", (0, 0), (-1, 0), 0.8, colors.HexColor("#163f56")),
                ("LINEBELOW", (0, 0), (-1, 0), 0.5, colors.HexColor("#163f56")),
                ("LINEBELOW", (0, -1), (-1, -1), 0.8, colors.HexColor("#163f56")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]))
            story.append(KeepTogether([table, Spacer(1, 8)]))
        else:
            paragraph.append(line)
        index += 1
    flush()

    def header_footer(canvas, document):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.HexColor("#52616b"))
        canvas.drawRightString(543, 26, str(document.page))
        canvas.restoreState()
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    print(str(destination))


if __name__ == "__main__":
    main()
