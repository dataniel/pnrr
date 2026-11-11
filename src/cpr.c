#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include <math.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>

/* Shared normalisation: remove separators, pad exactly nine digits.
   The parser never constructs cleaned R strings. clean_cpr uses the same scan. */

/* Bytes of separator at s, 0 if none. Separators are the ASCII space, dash
   and whitespace (tab, line breaks), and what Excel and Word put in their
   place: the no-break space, the typographic dashes U+2010 to U+2015 and
   the minus sign U+2212. These are read as UTF-8, or as single bytes in
   strings marked Latin-1. */
static int sep_len(const unsigned char *s, int latin1) {
    unsigned char c = *s;
    if (c == ' ' || c == '-' || (c >= '\t' && c <= '\r')) return 1;
    if (c < 0x80) return 0;
    if (latin1) return c == 0xA0 || c == 0x96 || c == 0x97;
    if (c == 0xC2 && s[1] == 0xA0) return 2;
    if (c == 0xE2) {
        if (s[1] == 0x80 && s[2] >= 0x90 && s[2] <= 0x95) return 3;
        if (s[1] == 0x88 && s[2] == 0x92) return 3;
    }
    return 0;
}
typedef struct {
    int digits[10];
    int valid_format;
    int changed;
    int pad;
    int sep;        /* contained a separator */
    int count;      /* bytes left after removing separators */
    int all_digits; /* those bytes are all ASCII digits */
} CprScan;

static CprScan scan_cpr(SEXP string) {
    CprScan scan = {{0}, 0, 0, 0, 0, 0, 1};
    if (string == NA_STRING) return scan;
    const unsigned char *s = (const unsigned char *) CHAR(string);
    int count = 0, all_digits = 1, latin1 = Rf_getCharCE(string) == CE_LATIN1;
    for (; *s; ++s) {
        if (*s < '0' || *s > '9') {
            int len = sep_len(s, latin1);
            if (len) { scan.changed = scan.sep = 1; s += len - 1; continue; }
            all_digits = 0;
        }
        if (count < 10) scan.digits[count] = *s - '0';
        ++count;
    }
    scan.count = count;
    scan.all_digits = all_digits;
    if (!all_digits || (count != 9 && count != 10)) return scan;
    if (count == 9) {
        for (int j = 9; j > 0; --j) scan.digits[j] = scan.digits[j - 1];
        scan.digits[0] = 0;
        scan.pad = scan.changed = 1;
    }
    scan.valid_format = 1;
    return scan;
}

/* A CPR number stored as a number: the digits are read directly, with the
   result as.character() and scan_cpr() would give (a sign is a separator,
   nine digits are padded), but without building a string per value. */
static CprScan scan_number(double v) {
    CprScan scan = {{0}, 0, 0, 0, 0, 0, 1};
    if (!R_FINITE(v)) return scan;
    v = fabs(v);
    if (v < 1e8 || v >= 1e10 || v != floor(v)) return scan;
    int64_t u = (int64_t) v;
    for (int j = 9; j >= 0; --j) { scan.digits[j] = (int)(u % 10); u /= 10; }
    scan.valid_format = 1;
    return scan;
}

SEXP pnrr_clean_cpr(SEXP x) {
    if (TYPEOF(x) != STRSXP) Rf_error("Internal error: CPR input must be character.");
    R_xlen_t n = XLENGTH(x);
    SEXP out = x;
    int nprotect = 0;
    char *buffer = NULL;
    size_t capacity = 0;
    for (R_xlen_t i = 0; i < n; ++i) {
        if ((i & 65535) == 0) R_CheckUserInterrupt();
        SEXP string = STRING_ELT(x, i);
        CprScan scan = scan_cpr(string);
        if (!scan.changed) continue;
        if (out == x) {
            out = PROTECT(Rf_duplicate(x));
            ++nprotect;
        }
        size_t required = (size_t)LENGTH(string) + 2;
        if (required > capacity) {
            capacity = required > capacity * 2 ? required : capacity * 2;
            buffer = (char *) R_alloc(capacity, 1);
        }
        const unsigned char *s = (const unsigned char *) CHAR(string);
        int latin1 = Rf_getCharCE(string) == CE_LATIN1;
        size_t k = 0;
        if (scan.pad) buffer[k++] = '0';
        for (; *s; ++s) {
            int len = sep_len(s, latin1);
            if (len) s += len - 1; else buffer[k++] = (char) *s;
        }
        SET_STRING_ELT(out, i, Rf_mkCharLenCE(buffer, (int)k, Rf_getCharCE(string)));
    }
    UNPROTECT(nprotect);
    return out;
}

static int valid_date(int y, int m, int d) {
    static const int days[] = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (m < 1 || m > 12 || d < 1) return 0;
    return d <= days[m - 1] + (m == 2 && y % 4 == 0 && (y % 100 != 0 || y % 400 == 0));
}

static double days_from_civil(int y, int m, int d) {
    y -= m <= 2;
    int era = (y >= 0 ? y : y - 399) / 400;
    int yoe = y - era * 400;
    int mp = m + (m > 2 ? -3 : 9);
    int doy = (153 * mp + 2) / 5 + d - 1;
    return era * 146097.0 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468;
}

/* Birth date from the first seven digits; the seventh selects the century. */
static int decode_birth(const int *v, int *y, int *m, int *d) {
    *d = v[0]*10 + v[1]; *m = v[2]*10 + v[3];
    int yy = v[4]*10 + v[5], century = 1900;
    if ((v[6] == 4 || v[6] == 9) && yy <= 36) century = 2000;
    if (v[6] >= 5 && v[6] <= 8) century = yy <= 57 ? 2000 : 1800;
    *y = century + yy;
    return valid_date(*y, *m, *d);
}

static int mod11(const int *v) {
    static const int weights[] = {4,3,2,7,6,5,4,3,2,1};
    int sum = 0;
    for (int k = 0; k < 10; ++k) sum += v[k] * weights[k];
    return sum % 11 == 0;
}

/* Inverse civil-day arithmetic, independent of timezone and strptime. */
static void civil_from_days(double z, double *year, int *md) {
    if (!R_FINITE(z) || fabs(z) > 1e12) { *year = NA_REAL; *md = 0; return; }
    int64_t days = (int64_t)floor(z) + 719468;
    int64_t era = (days >= 0 ? days : days - 146096) / 146097;
    unsigned int doe = (unsigned int)(days - era * 146097);
    unsigned int yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    unsigned int doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    int mp = (int)((5 * doy + 2) / 153);
    int d = (int)doy - (153 * mp + 2) / 5 + 1;
    int m = mp + (mp < 10 ? 3 : -9);
    *year = yoe + era * 400.0 + (m <= 2);
    *md = m * 100 + d;
}

typedef struct {
    const double *value;
    const int *ivalue;  /* years stored as integers, else NULL */
    const SEXP *strings;
    int kind;
    int at;
    int offset;         /* added to a year: -1 for the previous ultimo */
    R_xlen_t length;
    const char *name;
} Reference;

static void read_reference(const Reference *ref, R_xlen_t i, double *year, int *md) {
    R_xlen_t k = ref->length == 1 ? 0 : i;
    if (ref->kind == 0) {
        *md = ref->at;
        if (ref->ivalue) *year = ref->ivalue[k] == NA_INTEGER ? NA_REAL : ref->ivalue[k] + ref->offset;
        else *year = ref->value[k] + ref->offset;
        return;
    }
    if (ref->kind == 1) { civil_from_days(ref->value[k], year, md); return; }
    SEXP string = ref->strings[k];
    if (string == NA_STRING) { *year = NA_REAL; *md = 0; return; }
    const char *s = CHAR(string);
    int digits[8], kdigit = 0;
    int ok = LENGTH(string) == 10;
    if (ok) {
        for (int j = 0; j < 10; ++j) {
            if (j == 4 || j == 7) { if (s[j] != '-') ok = 0; }
            else if (s[j] < '0' || s[j] > '9') { ok = 0; break; }
            else digits[kdigit++] = s[j] - '0';
        }
    }
    int y = 0, m = 0, d = 0;
    if (ok) {
        y = digits[0]*1000 + digits[1]*100 + digits[2]*10 + digits[3];
        m = digits[4]*10 + digits[5]; d = digits[6]*10 + digits[7];
        ok = valid_date(y, m, d);
    }
    if (!ok) Rf_error("date for `%s` must contain valid ISO dates (YYYY-MM-DD).", ref->name);
    *year = y; *md = m*100 + d;
}

/* Year references are validated here, in one pass and without the temporary
   vectors the same test costs in R. NA is allowed and gives a missing age.
   0: fine; 1: not whole years between 1 and 9999; 2: a year below min. */
SEXP pnrr_year_status(SEXP value, SEXP min) {
    int lo = Rf_asInteger(min), status = 0;
    R_xlen_t n = XLENGTH(value);
    if (TYPEOF(value) == INTSXP) {
        const int *v = INTEGER(value);
        for (R_xlen_t i = 0; i < n; ++i) {
            if (v[i] == NA_INTEGER) continue;
            if (v[i] < 1 || v[i] > 9999) return Rf_ScalarInteger(1);
            if (v[i] < lo) status = 2;
        }
    } else if (TYPEOF(value) == REALSXP) {
        const double *v = REAL(value);
        for (R_xlen_t i = 0; i < n; ++i) {
            double y = v[i];
            if (ISNAN(y)) continue;
            if (!(y >= 1 && y <= 9999) || y != floor(y)) return Rf_ScalarInteger(1);
            if (y < lo) status = 2;
        }
    } else status = 1;
    return Rf_ScalarInteger(status);
}

static int status_of(SEXP string, const CprScan *scan, int date_ok);

/* codes: 0 bday, 1 age, 2 sex, 3 mod11, 4 valid, 5 byear, 6 koen, 7 status.
   One CPR scan per row. x is character, or numeric with the CPR numbers as
   numbers; status works on the written form and needs character. */
SEXP pnrr_cpr_info(SEXP x, SEXP codes, SEXP references) {
    int xtype = TYPEOF(x);
    if ((xtype != STRSXP && xtype != REALSXP && xtype != INTSXP) ||
        TYPEOF(codes) != INTSXP || TYPEOF(references) != VECSXP)
        Rf_error("Internal error: invalid CPR arguments.");
    R_xlen_t n = XLENGTH(x);
    const double *xreal = xtype == REALSXP ? REAL(x) : NULL;
    const int *xint = xtype == INTSXP ? INTEGER(x) : NULL;
    int p = Rf_length(codes);
    const int *type = INTEGER(codes);
    SEXP out = PROTECT(Rf_allocVector(VECSXP, p));
    int **ints = (int **) R_alloc(p, sizeof(int *));
    double **reals = (double **) R_alloc(p, sizeof(double *));
    Reference *refs = (Reference *) R_alloc(p, sizeof(Reference));
    double *scalar_year = (double *) R_alloc(p, sizeof(double));
    int *scalar_md = (int *) R_alloc(p, sizeof(int));
    int need_calendar = 0, need_checksum = 0, need_bday = 0, need_status = 0;
    for (int j = 0; j < p; ++j) {
        int code = type[j];
        if (code < 0 || code > 7) Rf_error("Internal error: unknown CPR output.");
        if (code == 7 && xtype != STRSXP) Rf_error("Internal error: status needs character input.");
        need_calendar |= code != 3; need_checksum |= code == 3; need_bday |= code == 0;
        need_status |= code == 7;
        int logical = code == 3 || code == 4;
        SEXP col = PROTECT(Rf_allocVector(code == 0 ? REALSXP : (logical ? LGLSXP : INTSXP), n));
        if (code == 0) {
            SEXP cls = PROTECT(Rf_mkString("Date"));
            Rf_setAttrib(col, R_ClassSymbol, cls);
            UNPROTECT(1);
            reals[j] = REAL(col);
        } else ints[j] = logical ? LOGICAL(col) : INTEGER(col);
        if (code == 7) {
            /* A factor, with the statuses of diagnose_cpr() as levels. */
            static const char *const names[] = {"valid", "missing", "scientific",
                "wrong_length", "non_digit", "invalid_date"};
            SEXP levels = PROTECT(Rf_allocVector(STRSXP, 6));
            for (int l = 0; l < 6; ++l) SET_STRING_ELT(levels, l, Rf_mkChar(names[l]));
            Rf_setAttrib(col, R_LevelsSymbol, levels);
            SEXP cls = PROTECT(Rf_mkString("factor"));
            Rf_setAttrib(col, R_ClassSymbol, cls);
            UNPROTECT(2);
        }
        SET_VECTOR_ELT(out, j, col);
        UNPROTECT(1);
        if (code == 1) {
            SEXP spec = VECTOR_ELT(references, j);
            SEXP value = VECTOR_ELT(spec, 0);
            refs[j].kind = Rf_asInteger(VECTOR_ELT(spec, 1));
            refs[j].at = Rf_asInteger(VECTOR_ELT(spec, 2));
            refs[j].name = CHAR(STRING_ELT(VECTOR_ELT(spec, 3), 0));
            refs[j].length = XLENGTH(value);
            if (refs[j].length != 1 && refs[j].length != n) Rf_error("Internal error: reference length mismatch.");
            refs[j].ivalue = NULL;
            refs[j].offset = refs[j].kind == 0 ? Rf_asInteger(VECTOR_ELT(spec, 4)) : 0;
            int vtype = TYPEOF(value);
            if (refs[j].kind == 2 && vtype == STRSXP) refs[j].strings = STRING_PTR_RO(value);
            else if (refs[j].kind == 0 && vtype == INTSXP) refs[j].ivalue = INTEGER(value);
            else if (refs[j].kind != 2 && vtype == REALSXP) refs[j].value = REAL(value);
            else Rf_error("Internal error: invalid reference type.");
            if (refs[j].length == 1) read_reference(&refs[j], 0, &scalar_year[j], &scalar_md[j]);
        }
    }
    for (R_xlen_t i = 0; i < n; ++i) {
        if ((i & 65535) == 0) R_CheckUserInterrupt();
        SEXP string = xtype == STRSXP ? STRING_ELT(x, i) : R_NilValue;
        CprScan scan = xreal ? scan_number(xreal[i])
            : xint ? scan_number(xint[i] == NA_INTEGER ? NA_REAL : xint[i])
            : scan_cpr(string);
        int valid = 0, y = 0, m = 0, d = 0, checksum = NA_LOGICAL;
        double bday = NA_REAL;
        if (scan.valid_format) {
            if (need_calendar) {
                valid = decode_birth(scan.digits, &y, &m, &d);
                if (valid && need_bday) bday = days_from_civil(y, m, d);
            }
            if (need_checksum) checksum = mod11(scan.digits);
        }
        /* Integer outputs by code; bday (0) and age (1) are handled apart. */
        int fixed[8];
        fixed[2] = valid ? scan.digits[9] % 2 : NA_INTEGER;
        fixed[3] = checksum;
        fixed[4] = valid;
        fixed[5] = valid ? y : NA_INTEGER;
        fixed[6] = valid ? 2 - scan.digits[9] % 2 : NA_INTEGER;
        fixed[7] = need_status ? status_of(string, &scan, valid) + 1 : NA_INTEGER;
        for (int j = 0; j < p; ++j) {
            int code = type[j];
            if (code == 0) reals[j][i] = bday;
            else if (code == 1) {
                double ry; int md;
                if (refs[j].length == 1) { ry = scalar_year[j]; md = scalar_md[j]; }
                else read_reference(&refs[j], i, &ry, &md);
                double a = ry - y - (md < m*100 + d);
                ints[j][i] = valid && R_FINITE(a) && a > INT_MIN && a <= INT_MAX ? (int)a : NA_INTEGER;
            } else ints[j][i] = fixed[code];
        }
    }
    UNPROTECT(1);
    return out;
}

/* Matches ^[0-9]+([.,][0-9]+)?([eE][+]?[0-9]+)?$ with at least a decimal
   part or an exponent, ignoring separators as clean_cpr does. */
static int is_scientific(const unsigned char *s, int latin1) {
    /* 0 integer digits, 1 after separator, 2 fraction digits,
       3 after e, 4 after +, 5 exponent digits */
    int state = 0, digits = 0;
    for (; *s; ++s) {
        unsigned char c = *s;
        int len = sep_len(s, latin1);
        if (len) { s += len - 1; continue; }
        int digit = c >= '0' && c <= '9';
        switch (state) {
            case 0:
                if (digit) digits = 1;
                else if (digits && (c == '.' || c == ',')) state = 1;
                else if (digits && (c == 'e' || c == 'E')) state = 3;
                else return 0;
                break;
            case 1: if (!digit) return 0; state = 2; break;
            case 2:
                if (c == 'e' || c == 'E') state = 3;
                else if (!digit) return 0;
                break;
            case 3:
                if (c == '+') state = 4;
                else if (digit) state = 5;
                else return 0;
                break;
            case 4: if (!digit) return 0; state = 5; break;
            case 5: if (!digit) return 0; break;
        }
    }
    return state == 2 || state == 5;
}

/* The one status every value has: 0 valid, 1 missing, 2 scientific,
   3 wrong_length, 4 non_digit, 5 invalid_date. date_ok says whether a
   value in valid format encodes a real date. Shared by diagnose_cpr() and
   the status selection, so the two cannot disagree. */
static int status_of(SEXP string, const CprScan *scan, int date_ok) {
    if (string == NA_STRING || scan->count == 0) return 1;
    if (scan->valid_format) return date_ok ? 0 : 5;
    if (scan->all_digits) return 3;
    return is_scientific((const unsigned char *) CHAR(string),
                         Rf_getCharCE(string) == CE_LATIN1) ? 2 : 4;
}

/* One pass for diagnose_cpr(). Each value gets one status, as in
   status_of(); and note bits: 1 zero_restored, 2 separators,
   4 mod11_fails, 8 born after as_of, 16 born before oldest.
   Returns the row numbers of the 11 checks, a numeric key for valid
   values (for repeats), the birth date range and the count of males. */
SEXP pnrr_cpr_diagnose(SEXP x, SEXP as_of, SEXP oldest) {
    if (TYPEOF(x) != STRSXP || TYPEOF(as_of) != REALSXP || TYPEOF(oldest) != REALSXP)
        Rf_error("Internal error: invalid diagnosis arguments.");
    R_xlen_t n = XLENGTH(x);
    if (n > INT_MAX) Rf_error("diagnose_cpr() supports at most %d values.", INT_MAX);
    double after = REAL(as_of)[0], before = REAL(oldest)[0];
    unsigned char *status = (unsigned char *) R_alloc(n ? n : 1, 1);
    unsigned char *notes = (unsigned char *) R_alloc(n ? n : 1, 1);
    SEXP key = PROTECT(Rf_allocVector(REALSXP, n));
    double *k = REAL(key);
    R_xlen_t counts[11] = {0};
    double first = R_PosInf, last = R_NegInf, male = 0;
    for (R_xlen_t i = 0; i < n; ++i) {
        if ((i & 65535) == 0) R_CheckUserInterrupt();
        SEXP string = STRING_ELT(x, i);
        CprScan scan = scan_cpr(string);
        int y = 0, m = 0, d = 0;
        int date_ok = scan.valid_format && decode_birth(scan.digits, &y, &m, &d);
        int st = status_of(string, &scan, date_ok), nb = scan.pad | (scan.sep << 1);
        k[i] = NA_REAL;
        if (st == 0) {
            double bday = days_from_civil(y, m, d);
            if (!mod11(scan.digits)) nb |= 4;
            if (bday > after) nb |= 8;
            if (bday < before) nb |= 16;
            if (bday < first) first = bday;
            if (bday > last) last = bday;
            male += scan.digits[9] % 2;
            double value = 0;
            for (int j = 0; j < 10; ++j) value = value * 10 + scan.digits[j];
            k[i] = value;
        }
        status[i] = (unsigned char) st;
        notes[i] = (unsigned char) nb;
        ++counts[st];
        for (int b = 0; b < 5; ++b) if (nb & (1 << b)) ++counts[6 + b];
    }
    SEXP rows = PROTECT(Rf_allocVector(VECSXP, 11));
    int *fill[11];
    for (int j = 0; j < 11; ++j) {
        SET_VECTOR_ELT(rows, j, Rf_allocVector(INTSXP, counts[j]));
        fill[j] = INTEGER(VECTOR_ELT(rows, j));
    }
    for (R_xlen_t i = 0; i < n; ++i) {
        int row = (int) i + 1;
        *fill[status[i]]++ = row;
        int nb = notes[i];
        if (nb) for (int b = 0; b < 5; ++b) if (nb & (1 << b)) *fill[6 + b]++ = row;
    }
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
    SET_VECTOR_ELT(out, 0, rows);
    SET_VECTOR_ELT(out, 1, key);
    SEXP range = Rf_allocVector(REALSXP, 2);
    SET_VECTOR_ELT(out, 2, range);
    REAL(range)[0] = counts[0] ? first : NA_REAL;
    REAL(range)[1] = counts[0] ? last : NA_REAL;
    SET_VECTOR_ELT(out, 3, Rf_ScalarReal(male));
    UNPROTECT(3);
    return out;
}

static const R_CallMethodDef call_methods[] = {
    {"pnrr_clean_cpr", (DL_FUNC) &pnrr_clean_cpr, 1},
    {"pnrr_cpr_info", (DL_FUNC) &pnrr_cpr_info, 3},
    {"pnrr_year_status", (DL_FUNC) &pnrr_year_status, 2},
    {"pnrr_cpr_diagnose", (DL_FUNC) &pnrr_cpr_diagnose, 3},
    {NULL, NULL, 0}
};

void attribute_visible R_init_pnrr(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
