#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "bel-parser.h"

const char* eof = EOF;

bel_arg_stack* stack_init(int max) {
    bel_arg_stack* stack;
    bel_ast_node*  contents;

    stack = (bel_arg_stack *) malloc(sizeof(bel_arg_stack));
    contents = (bel_ast_node *) malloc(sizeof(bel_ast_node) * max);

    if (contents == NULL) {
        fprintf(stderr, "Insufficient memory to initialize stack.\n");
        exit(1);  /* Exit, returning error code. */
    }

    stack->top      = -1;
    stack->max      = max;
    stack->contents = contents;

    return stack;
};

void stack_destroy(bel_arg_stack* stack) {
    free(stack->contents);
    stack->top = -1;
    stack->max = 0;
    stack->contents = NULL;
};

bel_ast_node* stack_peek(bel_arg_stack* stack) {
    if (stack_is_full(stack)) {
        fprintf(stderr, "Can't push element on stack: stack is full.\n");
        exit(1);
    }

    bel_ast_node* top = &(stack->contents[stack->top]);
    return top;
};

void stack_push(bel_arg_stack* stack, bel_ast_node element) {
    if (stack_is_full(stack)) {
        fprintf(stderr, "Can't push element on stack: stack is full.\n");
        exit(1);
    }

    stack->contents[++stack->top] = element;
};

bel_ast_node stack_pop(bel_arg_stack* stack) {
    if (stack_is_empty(stack)) {
        fprintf(stderr, "Can't pop element from stack: stack is empty.\n");
        exit(1);
    }

    return stack->contents[stack->top--];
};

int stack_is_empty(bel_arg_stack* stack) {
    return stack->top < 0;
};

int stack_is_full(bel_arg_stack* stack) {
    return stack->top >= stack->max - 1;
};

bel_ast_node* bel_new_ast_node_token(bel_ast_token_type type) {
    bel_ast_node* node;
    node = malloc(sizeof(bel_ast_node));
    node->token = malloc(sizeof(bel_ast_node_token));
    node->token->type  = TOKEN;
    node->token->ttype = type;
    node->token->left  = NULL;
    node->token->right = NULL;
    return node;
};

bel_ast_node* bel_new_ast_node_value(bel_ast_value_type type, char value[]) {
    bel_ast_node* node;
    char*         copy_value;

    if (value) {
        copy_value = malloc(sizeof(char) * (strlen(value) + 1));
        strcpy(copy_value, value);
    } else {
        copy_value = NULL;
    }

    node = malloc(sizeof(bel_ast_node));
    node->value = malloc(sizeof(bel_ast_node_value));
    node->value->type  = VALUE;
    node->value->vtype = type;
    node->value->value = copy_value;
    return node;
};

bel_ast* bel_new_ast() {
    bel_ast* ast;
    ast = malloc(sizeof(bel_ast));
    ast->root = NULL;
    return ast;
};

void bel_free_ast(bel_ast* ast) {
    if (!ast) {
        return;
    }
    bel_free_ast_node(ast->root);
    free(ast);
};

void bel_free_ast_node(bel_ast_node* node) {
    if (node->type_info->type == TOKEN && node->token->ttype != TOKEN_NIL) {
        bel_free_ast_node(node->token->left);
        bel_free_ast_node(node->token->right);
    }
    free(node);
};

void bel_print_ast_node(bel_ast_node* node) {
    if (!node) {
        return;
    }

    switch(node->type_info->type) {
    case TOKEN:
        switch(node->type_info->ttype) {
            case TOKEN_ARG:
                fprintf(stdout, "ARG\n");
                break;
            case TOKEN_NIL:
                fprintf(stdout, "NIL\n");
                break;
            case TOKEN_NV:
                fprintf(stdout, "NV\n");
                break;
            case TOKEN_TERM:
                fprintf(stdout, "TERM\n");
                break;
        }
        bel_print_ast_node(node->token->left);
        bel_print_ast_node(node->token->right);
        break;
    case VALUE:
        switch(node->type_info->vtype) {
            case VALUE_FX:
                fprintf(stdout, "fx(%s)\n", node->value->value);
                break;
            case VALUE_NIL:
                fprintf(stdout, "nil(%s)\n", node->value->value);
                break;
            case VALUE_PFX:
                fprintf(stdout, "pfx(%s)\n", node->value->value);
                break;
            case VALUE_VAL:
                fprintf(stdout, "val(%s)\n", node->value->value);
                break;
        }
        break;
    }
};

void bel_print_ast_node_flat(bel_ast_node* node, char* tree_flat_string) {
    if (!node) {
        return;
    }

    char val[VALUE_SIZE];
    switch(node->type_info->type) {
        case TOKEN:
            switch(node->type_info->ttype) {
                case TOKEN_ARG:
                    strcat(tree_flat_string, "ARG ");
                    break;
                case TOKEN_NIL:
                    strcat(tree_flat_string, "NIL ");
                    break;
                case TOKEN_NV:
                    strcat(tree_flat_string, "NV ");
                    break;
                case TOKEN_TERM:
                    strcat(tree_flat_string, "TERM ");
                    break;
            };
            bel_print_ast_node_flat(node->token->left, tree_flat_string);
            bel_print_ast_node_flat(node->token->right, tree_flat_string);
            break;
        case VALUE:
            switch(node->type_info->vtype) {
                case VALUE_FX:
                    sprintf(val, "fx(%s) ", node->value->value);
                    strcat(tree_flat_string, val);
                    break;
                case VALUE_NIL:
                    sprintf(val, "nil(%s) ", node->value->value);
                    strcat(tree_flat_string, val);
                    break;
                case VALUE_PFX:
                    sprintf(val, "pfx(%s) ", node->value->value);
                    strcat(tree_flat_string, val);
                    break;
                case VALUE_VAL:
                    sprintf(val, "val(%s) ", node->value->value);
                    strcat(tree_flat_string, val);
                    break;
            };
            break;
    };
};

void bel_print_ast(bel_ast* ast) {
    if (!ast) {
        return;
    }
    bel_print_ast_node(ast->root);
    fprintf(stdout, "\n");
};

void bel_print_ast_flat(bel_ast* ast) {
    if (!ast) {
        return;
    }

    char tree_flat_string[1024];
    memset(tree_flat_string, '\0', 1024);
    bel_print_ast_node_flat(ast->root, tree_flat_string);
    fprintf(stdout, "%s\n", tree_flat_string);
};

char* bel_ast_flat_string(bel_ast* ast) {
    if (!ast) {
        return NULL;
    }

    char tree_flat_string[1024];
    memset(tree_flat_string, '\0', 1024);
    bel_print_ast_node_flat(ast->root, tree_flat_string);
    return tree_flat_string;
};

%%{
    machine set;
    write data;
}%%

bel_ast* parse_term(char* line, char value[]) {
    int            cs;
    char           *p;
    char           *pe;
    bel_ast_node*  current_term;
    bel_ast_node*  current_nv;
    bel_ast_node*  arg;
    bel_ast_node*  next_arg;
    bel_ast*       ast;
    bel_arg_stack* arg_stack;
    int            vi;

    p            = line;
    pe           = line + strlen(line);
    current_term = NULL;
    current_nv   = NULL;
    arg          = NULL;
    next_arg     = NULL;
    ast          = bel_new_ast();
    arg_stack    = stack_init(ARG_STACK_SIZE);
    vi           = 0;

    %%{
        action vi {
            value[vi++] = fc;
        }

        action FX {
            current_term = bel_new_ast_node_token(TOKEN_TERM);
            current_term->token->left = bel_new_ast_node_value(VALUE_FX,  value);

            // Set term as AST root; on first term
            if (!ast->root) {
                ast->root = current_term;
            }

            // Create Nil argument as a placeholder; add to stack
            arg = bel_new_ast_node_token(TOKEN_ARG);
            arg->token->left  = bel_new_ast_node_token(TOKEN_NIL);
            arg->token->right = bel_new_ast_node_token(TOKEN_NIL);
            stack_push(arg_stack, *arg);

            // Set as term argument
            current_term->token->right = arg;

            memset(value, '\0', VALUE_SIZE);
            vi = 0;
        }

        action PFX {
            bel_ast_node* top = stack_peek(arg_stack);
            current_nv = bel_new_ast_node_token(TOKEN_NV);
            current_nv->token->left  = bel_new_ast_node_value(VALUE_PFX, value);
            current_nv->token->right = bel_new_ast_node_value(VALUE_VAL, "");
            top->token->left = current_nv;

            next_arg = bel_new_ast_node_token(TOKEN_ARG);
            next_arg->token->left  = bel_new_ast_node_token(TOKEN_NIL);
            next_arg->token->right = bel_new_ast_node_token(TOKEN_NIL);
            top->token->right = next_arg;
            stack_push(arg_stack, *next_arg);

            memset(value, '\0', VALUE_SIZE);
            vi = 0;
        }

        action VAL {
            bel_ast_node* top = stack_peek(arg_stack);
            if (!current_nv) {
                current_nv = bel_new_ast_node_token(TOKEN_NV);
                current_nv->token->left  = bel_new_ast_node_value(VALUE_PFX, "");
                current_nv->token->right = bel_new_ast_node_value(VALUE_VAL, value);
                top->token->left = current_nv;

                next_arg = bel_new_ast_node_token(TOKEN_ARG);
                next_arg->token->left  = bel_new_ast_node_token(TOKEN_NIL);
                next_arg->token->right = bel_new_ast_node_token(TOKEN_NIL);
                top->token->right = next_arg;
                stack_push(arg_stack, *next_arg);
            } else {
                current_nv->token->right = bel_new_ast_node_value(VALUE_VAL, value);
            }

            current_nv = 0;
            memset(value, '\0', VALUE_SIZE);
            vi = 0;
        }

        SP           = ' ';
        O_PAREN      = '(';
        C_PAREN      = ')';
        COLON        = ':';
        IDENT        = [a-zA-Z0-9_]+;
        STRING       = ('"' ('\\\"' | [^"])* '"');
        FUNCTION     = ('proteinAbundance'|'p'|'rnaAbundance'|'r'|'abundance'|'a'|'microRNAAbundance'|'m'|'geneAbundance'|'g'|'biologicalProcess'|'bp'|'pathology'|'path'|'complexAbundance'|'complex'|'translocation'|'tloc'|'cellSecretion'|'sec'|'cellSurfaceExpression'|'surf'|'reaction'|'rxn'|'compositeAbundance'|'composite'|'fusion'|'fus'|'degradation'|'deg'|'molecularActivity'|'act'|'catalyticActivity'|'cat'|'kinaseActivity'|'kin'|'phosphataseActivity'|'phos'|'peptidaseActivity'|'pep'|'ribosylationActivity'|'ribo'|'transcriptionalActivity'|'tscript'|'transportActivity'|'tport'|'gtpBoundActivity'|'gtp'|'chaperoneActivity'|'chap'|'proteinModification'|'pmod'|'substitution'|'sub'|'truncation'|'trunc'|'reactants'|'products'|'list');

        term =
            FUNCTION $vi %FX
            O_PAREN 
            (
                (IDENT $vi ':')? @PFX (STRING $vi | IDENT $vi) %VAL 
            )
            (
                SP* ',' SP*
                (IDENT $vi ':')? @PFX (STRING $vi | IDENT $vi) %VAL
            )*
            C_PAREN;

        main :=
            term;

        # Initialize and execute.
        write init;
        write exec;
    }%%

    if (arg_stack) {
        stack_destroy(arg_stack);
    }

    return ast;
};
// vim: ft=c sw=4 ts=4 sts=4 expandtab