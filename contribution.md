## Contributing to TecMon

Thank you for your interest in contributing to this public repository.

This guide is written for students and beginners who may be new to GitHub.
It explains the basic workflow for contributing a feature or fix.

### Scrum board

Before starting work, check the project Scrum board for current tasks and priorities:

https://pixelgames.atlassian.net/?continue=https%3A%2F%2Fpixelgames.atlassian.net%2Fwelcome%2Fsoftware%3FprojectId%3D10000&atlOrigin=eyJpIjoiZWNiYzVkMmIxNjBhNDM0OTlhNTU3Y2ZkZTAxNWY2ODgiLCJwIjoiamlyYS1zb2Z0d2FyZSJ9

If you are unsure what to work on, pick an open task from the board and ask a maintainer if you need clarification.

### 1. Fork the repository

1. Open the TecMon repository on GitHub.
2. Click **Fork** in the top-right corner.
3. GitHub will create a copy of the repository in your own account.

### 2. Clone your fork

Download your fork to your computer:

```bash
git clone https://github.com/your-username/TecMon.git
```

Replace `your-username` with your GitHub username.

Move into the project folder:

```bash
cd TecMon
```

### 3. Create a branch

Create a new branch for your work. Do not make changes directly on `main`.

```bash
git checkout -b my-feature-name
```

Example:

```bash
git checkout -b add-login-page
```

### 4. Make your changes

Edit the files needed for your feature or fix.

Check what changed:

```bash
git status
```

### 5. Commit your changes

Stage your changes:

```bash
git add .
```

Create a commit with a clear message:

```bash
git commit -m "Add login page"
```

### 6. Push your branch to GitHub

Send your branch to your fork:

```bash
git push origin my-feature-name
```

Example:

```bash
git push origin add-login-page
```

### 7. Open a pull request

1. Go to your fork on GitHub.
2. Click **Compare & pull request** if GitHub shows it.
3. Make sure the pull request is going to the original TecMon repository.
4. Write a short title and description of your changes.
5. Click **Create pull request**.

### Helpful tips

- Keep your changes small and focused.
- Use descriptive branch names.
- Write clear commit messages.
- Review your work before opening the pull request.
