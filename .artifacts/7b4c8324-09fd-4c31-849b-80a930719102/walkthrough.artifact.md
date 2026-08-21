# Walkthrough - Tally-Style Full Page A4 Invoices

I have enhanced the invoice generation system to produce professional, full-page A4 documents with multiple copies, similar to Tally ERP.

## Changes Made

### 1. Dual Copy Generation
Every time you generate a PDF (for Sales, Quotations, Proforma, or Service Bills), the app now creates **two pages**:
- **Page 1**: Labeled "**ORIGINAL FOR RECIPIENT**"
- **Page 2**: Labeled "**DUPLICATE FOR SUPPLIER**"

### 2. Full-Page A4 Layout
- **Placeholder Rows**: The item table now automatically includes empty rows to fill the vertical space of the A4 page. This ensures the totals and signature blocks are always consistently positioned near the bottom, giving the invoice a professional, balanced look regardless of how many items are listed.
- **Improved Borders**: Tightened the table styling to match standard Indian accounting formats (Tally-style).

### 3. Service Bill Standardization
Applied the same professional layout to **Service Jobs**, ensuring your service bills match the quality of your product invoices.

## How to Verify
1.  Open any **Sales Invoice** and click the **PDF icon**.
2.  Scroll through the preview; you will see two identical invoices with different "Original/Duplicate" labels at the top right.
3.  Observe that the table extends down to fill the page even if only one item is added.
4.  Print the document; it will now print two A4 sheets (or one double-sided) automatically.
