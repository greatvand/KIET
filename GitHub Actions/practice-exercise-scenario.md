# Practice Exercise: Continuous Integration with GitHub Actions (Scenario-Based)

> **Viewing note:** Open this file in a Markdown viewer (e.g. VS Code's built-in preview, MDViewer, or GitHub's rendered view) rather than a plain text editor — the headings, code blocks, and formatting are much easier to follow that way.

**Note:** The exam itself will be fully guided — step-by-step instructions. You will not need to recall or memorize any commands, menu paths, or YAML syntax on exam day.

**Format:** No step-by-step instructions. You're given a scenario and a set of requirements — you decide how to get there, using a GitHub Codespace from start to finish. This covers the same concepts as your exam: writing tests, building CI workflows, triggering them with a PR, enforcing branch protection, and fixing a failing pipeline.

---

## Scenario

You've joined a small team maintaining `contact-validator`, a Python library used to validate and format email addresses and phone numbers before they're saved to a database. The previous developer left behind some untested code and a half-written test suite. Your job is to get this repository into a state where broken code can never reach `main` again — and then prove your pipeline actually catches a real bug.

---

## Setup

1. Create a new **public** repository named `contact-validator-scenario`.
2. Open it in a Codespace.
3. Create the following structure and paste in the code exactly as given — do not "clean up" anything yet:

   ```
   src/contact_validator.py
   tests/contact_validator_test.py
   requirements.txt
   ```

### `src/contact_validator.py`

```python
import re


def is_valid_email(email):
    """Return True if email matches a basic pattern."""
    if not isinstance(email, str):
        raise TypeError("email must be a string")
    pattern = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    return re.match(pattern, email) is not None


def is_valid_phone(phone):
    """Return True if phone is exactly 10 digits, optionally with dashes."""
    if not isinstance(phone, str):
        raise TypeError("phone must be a string")
    digits_only = phone.replace("-", "")
    return digits_only.isdigit() and len(digits_only) == 10


def mask_email(email):
    """Mask an email like 'jo***@example.com'. Assumes email is already valid."""
    if not is_valid_email(email):
        raise ValueError("email is not valid")
    local, domain = email.split("@")
    if len(local) <= 2:
        masked_local = local[0] + "*" * (len(local) - 1)
    else:
        masked_local = local[:2] + "*" * (len(local) - 2)
    return f"{masked_local}@{domain}"


def normalize_phone(phone):
    """Return phone as digits-only, e.g. '555-123-4567' -> '5551234567'."""
    if not is_valid_phone(phone):
        raise ValueError("phone is not valid")
    return phone.replace("-", "")
```

### `tests/contact_validator_test.py`

```python
import pytest
from src.contact_validator import is_valid_email, is_valid_phone, mask_email, normalize_phone


def test_is_valid_email_true():
    """Test a well-formed email."""
    # Arrange
    email = "student@lpu.in"

    # Act
    result = is_valid_email(email)

    # Assert
    assert result == True


def test_is_valid_email_type_error():
    """Test that a non-string input raises TypeError."""
    with pytest.raises(TypeError):
        is_valid_email(12345)


def test_is_valid_phone_true():
    """Test a well-formed phone number with dashes."""
    # Arrange
    phone = "555-123-4567"

    # Act
    result = is_valid_phone(phone)

    # Assert
    assert result == True


# def test_mask_email_basic():
#     """Test masking a typical email address."""
#     # Arrange
#     email = "priya@example.com"
#
#     # Act
#     result = mask_email(email)
#
#     # Assert
#     assert result == "pr***@example.com"
```

### `requirements.txt`

```
pytest==8.4.1
coverage==7.9
pytest-cov==6.2.1
```

4. Commit and push all three files to `main`.

---

## Requirements

Your finished repository must satisfy every item below. You won't be told the exact menu path or the exact line of YAML to type — but each requirement explains clearly what needs to exist and why, so you can look up the specific mechanics yourself (the GitHub Actions documentation is fair game, and expected).

### 1. Baseline understanding

Before you change anything, run the existing test suite with coverage measurement turned on, inside your Codespace. Note two things:

- Your current overall coverage percentage.
- Which specific functions in `src/contact_validator.py` currently have **zero** tests exercising them.

You'll need both numbers later to know whether your fixes actually worked, so don't skip this — don't just assume.

### 2. Two CI workflows, both triggered only by pull requests targeting `main`

Neither workflow should run on a direct push to `main`. Think about why that restriction matters before you configure it — what could go wrong if a workflow only checked code that had already been merged?

- **Workflow A — Run the tests.** On every pull request into `main`, this workflow should set up Python, install the project's dependencies from `requirements.txt`, and run the full `pytest` suite. If any test fails, this workflow should fail too, and that failure should be visible on the pull request.

- **Workflow B — Enforce coverage.** On every pull request into `main`, this workflow should run the test suite again, this time measuring coverage against the `src` folder specifically. It must **fail the build if coverage drops below 85%** — not just report the number, but actually block the pipeline. Decide for yourself how you want the coverage result communicated (a posted comment, a step summary, a badge) and be ready to explain your choice.

### 3. A protected `main` branch

Set up branch protection so that a pull request cannot be merged while Workflow B (the coverage check) is failing. Concretely: if you open a pull request right now with failing coverage, the **Merge** button on GitHub should be disabled, not just "discouraged." Test this yourself rather than assuming it's configured correctly — open a pull request and confirm the button's actual state.

### 4. A demonstrated failure, followed by a fix

This is where you prove the pipeline you built actually works, not just that it exists.

- Create a new branch and, on it, re-enable the currently-disabled `test_mask_email_basic` test in `tests/contact_validator_test.py` — uncomment it exactly as written, without correcting anything yet.
- Push the branch and open a pull request into `main`.
- Confirm your pipeline correctly reports a failure on this pull request. Don't move on until you've actually seen it fail — a pipeline that never fails hasn't been tested.
- Open the failed run's logs and diagnose *why* it's failing. There is more than one distinct problem here — at least one is inside the test itself, and at least one is a coverage gap unrelated to that test. Find both before you start fixing anything.
- Fix each problem you found, one commit at a time if that helps you keep track: correct the faulty assertion first, then add whatever test coverage is missing to clear the 85% threshold (specifically for the function you noted as untested in Requirement 1).
- Push your fixes to the same branch and confirm the pull request's checks turn green and the pull request becomes mergeable.
- Merge it.

### 5. Proof of understanding

In your final pull request's description (before merging), write a short explanation covering:

- What was actually wrong — described in your own words, not just "I changed line X to Y."
- Why your CI setup caught this automatically, without a human reviewer needing to notice it by eye.

This description is part of the exercise, not an afterthought — grade yourself on whether someone unfamiliar with your repository could read it and understand what happened.

---

## Self-check before you consider this done

- Can someone else push a broken test directly to `main` right now? It shouldn't be possible.
- If you deleted your local coverage numbers, would you know how to regenerate them from Actions alone?
- Could you explain, without looking anything up, why `on: pull_request` was the right trigger choice here instead of `on: push`?

If you're unsure on any of these, that's a sign to go back and strengthen that part of the setup rather than move on.
