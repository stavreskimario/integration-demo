using Microsoft.AspNetCore.Mvc;
using Notes.Models;

namespace Notes.Controllers;

[ApiController]
[Route("[controller]")]
public class NotesController : ControllerBase
{
    // In-memory store (static so it survives across requests)
    private static readonly List<Note> _notes = new();
    private static int _nextId = 1;
    private static readonly string[] AllowedCategories = { "work", "personal", "other" };

    // POST /notes?category=work|personal|other
    [HttpPost]
    public IActionResult Create([FromBody] CreateNoteRequest request, [FromQuery] string? category)
    {
        try
        {
            // Validate required fields
            if (string.IsNullOrWhiteSpace(request.Title))
                return BadRequest(new { error = "Title is required." });

            if (string.IsNullOrWhiteSpace(request.Content))
                return BadRequest(new { error = "Content is required." });

            // Validate category
            var noteCategory = category?.ToLowerInvariant() ?? "other";

            if (!AllowedCategories.Contains(noteCategory))
                return BadRequest(new { error = $"Invalid category. Allowed values: {string.Join(", ", AllowedCategories)}" });

            var note = new Note
            {
                Id = _nextId++,
                Title = request.Title!,
                Content = request.Content!,
                Category = noteCategory,
                CreatedAt = DateTime.UtcNow
            };
            _notes.Add(note);

            return CreatedAtAction(nameof(GetAll), null, note);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "An unexpected error occurred.", details = ex.Message });
        }
    }

    // GET /notes?category=work|personal|other
    [HttpGet]
    public IActionResult GetAll([FromQuery] string? category)
    {
        try
        {
            var result = _notes.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(category))
            {
                result = result.Where(n => string.Equals(n.Category, category, StringComparison.OrdinalIgnoreCase));
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "An unexpected error occurred.", details = ex.Message });
        }
    }
}
